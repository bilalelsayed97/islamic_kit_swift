import Foundation
#if SWIFT_PACKAGE
import IslamicKitPlus
#endif

/// `Geocoder` backed by the bundled `prayer_times.db` (≈131k populated
/// places with English + Arabic names).
///
/// Queries are synchronous and serialize on one connection; share a single
/// instance for the process lifetime. A query failure (which a valid bundled
/// database never produces) yields an empty result rather than a crash.
public final class SqliteCityGeocoder: Geocoder, @unchecked Sendable {
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
    public static func bundled() throws -> SqliteCityGeocoder {
        try SqliteCityGeocoder(path: try BundledCityDatabase.url().path)
    }

    /// Returns matches for `query`, best first.
    ///
    /// `state` is accepted for interface compatibility but ignored: the
    /// bundled database carries no administrative-region column, so
    /// `City.state` is always `nil` here.
    public func search(_ query: String, country: String?, state: String?) -> [City] {
        let candidates = GeocoderMatching.candidates(query)
        if candidates.isEmpty { return [] }

        var countryId: Int?
        if let iso = GeocoderMatching.resolveCountry(country) {
            // An unknown country code can match nothing, mirroring the
            // behaviour of filtering on a code that is absent from the
            // database.
            guard let id = CountryIsoMap.isoToId[iso] else { return [] }
            countryId = id
        }

        var scored = [(city: City, score: Int, rank: Int, index: Int)]()
        for (index, row) in candidateRows(like: candidates[0], countryId: countryId).enumerated() {
            let en = row.text("city_name_en").map(StringHelpers.dartTrim) ?? ""
            let ar = row.text("city_name_ar").map(StringHelpers.dartTrim)
            let score = GeocoderMatching.score(GeocoderMatching.normalize(en), candidates)
                ?? ar.flatMap { GeocoderMatching.score(GeocoderMatching.normalize($0), candidates) }
            guard let score = score else { continue }
            scored.append((
                city: toCity(row, en, ar),
                score: score,
                rank: GeocoderMatching.placeRank(row.text("city_level")),
                index: index
            ))
        }
        // Equally good name matches are broken by settlement importance, so a
        // capital wins over a same-named village; the row index makes ties
        // deterministic (Dart leaves them unspecified).
        scored.sort { a, b in
            if a.score != b.score { return a.score < b.score }
            if a.rank != b.rank { return a.rank < b.rank }
            return a.index < b.index
        }
        return scored.map(\.city)
    }

    /// The first 200 populated places whose English or Arabic name contains
    /// `fragment`, optionally within one country.
    private func candidateRows(like fragment: String, countryId: Int?) -> [SQLiteRow] {
        var whereClause = "city_level LIKE 'PPL%' AND (city_name_en LIKE ? OR city_name_ar LIKE ?)"
        var args: [SQLiteBinding] = [.text("%\(fragment)%"), .text("%\(fragment)%")]
        if let countryId = countryId {
            whereClause += " AND country_id = ?"
            args.append(.int(countryId))
        }
        let sql = "SELECT city_name_en, city_name_ar, city_latitude, city_longitude, "
            + "city_time_zone, time_zone_id, country_id, city_level "
            + "FROM prayer_times_city_lookups WHERE \(whereClause) LIMIT 200"
        return (try? database.query(sql, args)) ?? []
    }

    private func toCity(_ row: SQLiteRow, _ en: String, _ ar: String?) -> City {
        City(
            name: en,
            country: row.int("country_id").flatMap { CountryIsoMap.idToIso[$0] } ?? "",
            coordinates: Coordinates(row.double("city_latitude") ?? 0, row.double("city_longitude") ?? 0),
            utcOffset: UTCOffset(
                seconds: 60 * GeocoderMatching.offsetMinutes(
                    timeZoneId: row.text("time_zone_id"), hours: row.double("city_time_zone")
                )
            ),
            nameAr: (ar?.isEmpty ?? true) ? nil : ar,
            state: nil
        )
    }
}
