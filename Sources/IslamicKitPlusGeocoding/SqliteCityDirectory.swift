import Foundation
#if SWIFT_PACKAGE
import IslamicKitPlus
#endif

/// Browsable, localized view over the bundled `prayer_times.db` — the
/// `CityDirectory` implementation the core library's `PrayerTimesService`
/// accepts as `directory:`.
///
/// `SqliteCityGeocoder` answers "which city is this text?"; this answers the
/// questions a location-picker asks instead — list the countries, page
/// through a country's cities, resolve GPS coordinates to a city, and offer
/// the timezones a country actually spans. Every method reads English and
/// Arabic names together so the caller can render either locale.
///
/// Queries are synchronous and serialize on one connection; share a single
/// instance for the process lifetime. A query failure (which a valid bundled
/// database never produces) yields an empty result / `nil`.
public final class SqliteCityDirectory: CityDirectory, @unchecked Sendable {
    private let database: SQLiteDatabase

    /// Wraps an already-open connection.
    public init(database: SQLiteDatabase) {
        self.database = database
    }

    /// Opens the database at `path` read-only.
    public convenience init(path: String) throws {
        self.init(database: try SQLiteDatabase(path: path))
    }

    /// Opens the bundled database in place.
    public static func bundled() throws -> SqliteCityDirectory {
        try SqliteCityDirectory(path: try BundledCityDatabase.url().path)
    }

    // MARK: - CityDirectory

    public func countries(query: String?) -> [CountryInfo] {
        let trimmed = query.map(StringHelpers.dartTrim) ?? ""
        let filtered = !trimmed.isEmpty
        let rows = select(
            "SELECT country_id, country_name_en, country_name_ar, calc_method "
                + "FROM prayer_times_country_lookups "
                + (filtered ? "WHERE (country_name_en LIKE ? OR country_name_ar LIKE ?) " : "")
                + "ORDER BY country_name_en COLLATE NOCASE",
            filtered ? [.text("%\(trimmed)%"), .text("%\(trimmed)%")] : []
        )
        return rows.map(toCountry)
    }

    public func country(_ countryId: Int) -> CountryInfo? {
        select(
            "SELECT country_id, country_name_en, country_name_ar, calc_method "
                + "FROM prayer_times_country_lookups WHERE country_id = ? LIMIT 1",
            [.int(countryId)]
        ).first.map(toCountry)
    }

    /// Prominence ordering matters here: a country's rows run to five figures
    /// and are dominated by neighbourhoods, so an alphabetical list buries the
    /// capital.
    public func citiesInCountry(_ countryId: Int, query: String?, limit: Int, offset: Int) -> [CityEntry] {
        cities(in: (clause: "c.country_id = ?", args: [.int(countryId)]), query: query, limit: limit, offset: offset)
    }

    public func searchCities(query: String?, limit: Int, offset: Int) -> [CityEntry] {
        cities(in: nil, query: query, limit: limit, offset: offset)
    }

    /// Not simply the closest row: the database records neighbourhoods
    /// alongside the cities that contain them, so a plain proximity sort
    /// answers "Az Zamalek" where a person would answer "Cairo". Distance is
    /// therefore weighted by settlement prominence, letting a nearby capital
    /// or administrative seat outrank a marginally closer suburb, and the
    /// search widens only if the initial box is empty.
    public func nearestCity(_ latitude: Double, _ longitude: Double) -> CityEntry? {
        for delta in [0.5, 2.0] {
            if let match = nearestWithin(latitude, longitude, delta) { return match }
        }
        return nearestWithin(latitude, longitude, nil)
    }

    /// Border towns carry a neighbour's zone, which would otherwise present
    /// Egypt as a four-zone country. A zone is included only when it covers
    /// at least 0.5% of the country's populated places, which keeps every
    /// genuine zone of even the most fragmented countries while dropping
    /// those strays.
    public func timeZonesForCountry(_ countryId: Int) -> [TimeZoneInfo] {
        let rows = select(
            "WITH zone_counts AS ("
                + "  SELECT TRIM(time_zone_id) AS zone, COUNT(*) AS n"
                + "    FROM prayer_times_city_lookups"
                + "   WHERE country_id = ? AND city_level LIKE 'PPL%'"
                + "     AND TRIM(COALESCE(time_zone_id, '')) <> ''"
                + "   GROUP BY zone) "
                + "SELECT z.zone, t.zone_name_ar "
                + "  FROM zone_counts z "
                + "  LEFT JOIN prayer_times_time_zone_lookups t ON t.time_zone_id = z.zone "
                + " WHERE z.n * 200 >= (SELECT SUM(n) FROM zone_counts) "
                + " ORDER BY z.zone COLLATE NOCASE",
            [.int(countryId)]
        )
        return rows.map { row in
            TimeZoneInfo(
                ianaId: row.text("zone") ?? "",
                countryId: countryId,
                nameAr: trimToNil(row.text("zone_name_ar"))
            )
        }
    }

    // MARK: - Internals

    private func select(_ sql: String, _ bindings: [SQLiteBinding]) -> [SQLiteRow] {
        (try? database.query(sql, bindings)) ?? []
    }

    /// `scope` narrows the query with an extra WHERE clause and its bindings.
    private func cities(
        in scope: (clause: String, args: [SQLiteBinding])?,
        query: String?,
        limit: Int,
        offset: Int
    ) -> [CityEntry] {
        let trimmed = query.map(StringHelpers.dartTrim) ?? ""
        var clauses = ["c.city_level LIKE 'PPL%'"]
        var bindings = scope?.args ?? []
        if let scope = scope { clauses.append(scope.clause) }
        if !trimmed.isEmpty {
            clauses.append("(c.city_name_en LIKE ? OR c.city_name_ar LIKE ?)")
            bindings.append(.text("%\(trimmed)%"))
            bindings.append(.text("%\(trimmed)%"))
        }
        let rows = select(
            "\(SqliteCityDirectory.citySelect) WHERE \(clauses.joined(separator: " AND ")) "
                + "ORDER BY \(SqliteCityDirectory.prominence), c.city_name_en COLLATE NOCASE "
                + "LIMIT ? OFFSET ?",
            bindings + [.int(limit), .int(offset)]
        )
        return rows.map(toCity)
    }

    private func nearestWithin(_ latitude: Double, _ longitude: Double, _ delta: Double?) -> CityEntry? {
        var clauses = ["c.city_level LIKE 'PPL%'"]
        var bindings = [SQLiteBinding]()
        if let delta = delta {
            clauses.append("c.city_latitude BETWEEN ? AND ?")
            clauses.append("c.city_longitude BETWEEN ? AND ?")
            bindings.append(.double(latitude - delta))
            bindings.append(.double(latitude + delta))
            bindings.append(.double(longitude - delta))
            bindings.append(.double(longitude + delta))
        }
        let rows = select(
            "\(SqliteCityDirectory.citySelect) WHERE \(clauses.joined(separator: " AND ")) "
                + "ORDER BY (((c.city_latitude - ?) * (c.city_latitude - ?)) "
                + "        + ((c.city_longitude - ?) * (c.city_longitude - ?))) "
                + "        * \(SqliteCityDirectory.prominenceWeight) "
                + "LIMIT 1",
            bindings + [.double(latitude), .double(latitude), .double(longitude), .double(longitude)]
        )
        return rows.first.map(toCity)
    }

    private static let citySelect =
        "SELECT c.city_id, c.city_name_en, c.city_name_ar, c.country_id, "
        + "c.city_latitude, c.city_longitude, c.city_time_zone, c.time_zone_id, "
        + "c.city_level, co.country_name_en, co.country_name_ar, co.calc_method "
        + "FROM prayer_times_city_lookups c "
        + "LEFT JOIN prayer_times_country_lookups co "
        + "  ON co.country_id = c.country_id"

    /// Settlement prominence as a sort key, most prominent first.
    private static let prominence = "CASE c.city_level "
        + "WHEN 'PPLC' THEN 0 WHEN 'PPLA' THEN 1 WHEN 'PPLA2' THEN 2 "
        + "WHEN 'PPLA3' THEN 3 WHEN 'PPLA4' THEN 4 WHEN 'PPL' THEN 5 ELSE 6 END"

    /// Distance multiplier that lets a prominent place outrank a closer suburb.
    private static let prominenceWeight = "CASE c.city_level "
        + "WHEN 'PPLC' THEN 1.0 WHEN 'PPLA' THEN 1.0 WHEN 'PPLA2' THEN 1.5 "
        + "WHEN 'PPLA3' THEN 2.0 WHEN 'PPLA4' THEN 2.5 ELSE 3.0 END"

    private func toCountry(_ row: SQLiteRow) -> CountryInfo {
        let id = row.int("country_id") ?? 0
        return CountryInfo(
            id: id,
            nameEn: row.text("country_name_en").map(StringHelpers.dartTrim) ?? "",
            nameAr: row.text("country_name_ar").map(StringHelpers.dartTrim) ?? "",
            isoCode: CountryIsoMap.idToIso[id] ?? "",
            calculationMethodId: row.int("calc_method")
        )
    }

    private func toCity(_ row: SQLiteRow) -> CityEntry {
        let countryId = row.int("country_id") ?? 0
        let timeZoneId = trimToNil(row.text("time_zone_id"))
        return CityEntry(
            id: row.int("city_id") ?? 0,
            nameEn: row.text("city_name_en").map(StringHelpers.dartTrim) ?? "",
            nameAr: row.text("city_name_ar").map(StringHelpers.dartTrim) ?? "",
            countryId: countryId,
            countryNameEn: row.text("country_name_en").map(StringHelpers.dartTrim) ?? "",
            countryNameAr: row.text("country_name_ar").map(StringHelpers.dartTrim) ?? "",
            isoCode: CountryIsoMap.idToIso[countryId] ?? "",
            coordinates: Coordinates(row.double("city_latitude") ?? 0, row.double("city_longitude") ?? 0),
            utcOffset: UTCOffset(
                seconds: 60 * GeocoderMatching.offsetMinutes(timeZoneId: timeZoneId, hours: row.double("city_time_zone"))
            ),
            timeZoneId: timeZoneId,
            calculationMethodId: row.int("calc_method")
        )
    }

    private func trimToNil(_ value: String?) -> String? {
        guard let trimmed = value.map(StringHelpers.dartTrim), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
