import XCTest
@testable import IslamicKitPlusGeocoding

/// `directory.json`: `CityDirectory` countries, pages, searches, nearest-city
/// lookups, time zones for all 251 countries and the automatic parameters
/// `PrayerTimesService` derives from them.
final class ConformanceDirectoryTests: XCTestCase {
    private struct File: Decodable {
        let countriesCount: Int
        let countries: [FixtureCountry]
        let countryQueries: [CountryQuery]
        let countryById: [CountryById]
        let citiesInCountry: [CityPage]
        let searchCities: [Search]
        let nearestCity: [Nearest]
        let timeZonesForCountry: [Zones]
        let autoParams: [AutoParams]
        let timingsByCoordinatesAuto: [AutoTimings]
    }

    private struct CountryQuery: Decodable {
        let query: String
        let results: [Int]
    }

    private struct CountryById: Decodable {
        let id: Int
        let result: FixtureCountry?
    }

    private struct CityPage: Decodable {
        let countryId: Int
        let query: String?
        let limit: Int
        let offset: Int
        let results: [FixtureEntry]
    }

    private struct Search: Decodable {
        let query: String?
        let limit: Int
        let offset: Int
        let results: [FixtureEntry]
    }

    private struct Nearest: Decodable {
        let lat: Double
        let lng: Double
        let result: FixtureEntry?
    }

    private struct Zone: Decodable, Hashable {
        let ianaId: String
        let nameAr: String?
    }

    private struct Zones: Decodable {
        let countryId: Int
        let zones: [Zone]
    }

    private struct AutoParams: Decodable {
        let lat: Double
        let lng: Double
        let params: FixtureParams?
    }

    private struct AutoTimings: Decodable {
        let lat: Double
        let lng: Double
        let date: String
        let raw: [String: Double?]?
    }

    private static let file: File = try! GeocodingFixtures.load("directory")

    private var directory: SqliteCityDirectory { TestDatabase.directory }

    /// Ordered comparison of a city page. SQLite leaves the order of rows
    /// that tie on every `ORDER BY` key to the scan, so when the lists hold
    /// the same rows but in a different order among equal-name neighbours
    /// the comparison falls back to the set and records the fact.
    private func assertEntries(
        _ actual: [CityEntry],
        _ expected: [FixtureEntry],
        _ context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let keys = actual.map(FixtureEntry.init)
        if keys == expected { return }
        if multiset(keys) == multiset(expected) {
            XCTFail("\(context): same rows, different order (SQLite tie order)", file: file, line: line)
            return
        }
        XCTFail("\(context): expected \(expected.map(\.id)) got \(keys.map(\.id))", file: file, line: line)
    }

    func testCountries() {
        let f = Self.file
        let countries = directory.countries()
        XCTAssertEqual(countries.count, f.countriesCount)
        XCTAssertEqual(countries.map(FixtureCountry.init), f.countries)
    }

    func testCountryQueries() {
        for q in Self.file.countryQueries {
            assertSame(directory.countries(query: q.query).map(\.id), q.results, "countries(query: \"\(q.query)\")")
        }
    }

    func testCountryById() {
        for c in Self.file.countryById {
            assertSame(directory.country(c.id).map(FixtureCountry.init), c.result, "country(\(c.id))")
        }
    }

    func testCitiesInCountry() {
        XCTAssertEqual(Self.file.citiesInCountry.count, 11)
        for p in Self.file.citiesInCountry {
            assertEntries(
                directory.citiesInCountry(p.countryId, query: p.query, limit: p.limit, offset: p.offset),
                p.results,
                "citiesInCountry(\(p.countryId), query: \(p.query ?? "nil"), limit: \(p.limit), offset: \(p.offset))"
            )
        }
    }

    func testSearchCities() {
        XCTAssertEqual(Self.file.searchCities.count, 12)
        for s in Self.file.searchCities {
            assertEntries(
                directory.searchCities(query: s.query, limit: s.limit, offset: s.offset),
                s.results,
                "searchCities(query: \(s.query ?? "nil"), limit: \(s.limit), offset: \(s.offset))"
            )
        }
    }

    func testNearestCity() {
        XCTAssertEqual(Self.file.nearestCity.count, 30)
        for n in Self.file.nearestCity {
            assertSame(directory.nearestCity(n.lat, n.lng).map(FixtureEntry.init), n.result, "nearestCity(\(n.lat), \(n.lng))")
        }
    }

    func testTimeZonesForEveryCountry() {
        XCTAssertEqual(Self.file.timeZonesForCountry.count, 251)
        for z in Self.file.timeZonesForCountry {
            let zones = directory.timeZonesForCountry(z.countryId).map { Zone(ianaId: $0.ianaId, nameAr: $0.nameAr) }
            assertSame(zones, z.zones, "timeZonesForCountry(\(z.countryId))")
            XCTAssertTrue(directory.timeZonesForCountry(z.countryId).allSatisfy { $0.countryId == z.countryId })
        }
    }

    func testAutoParams() throws {
        XCTAssertEqual(Self.file.autoParams.count, 12)
        let service = PrayerTimesService(directory: directory)
        for a in Self.file.autoParams {
            let context = "autoParamsForCoordinates(\(a.lat), \(a.lng))"
            let params = try service.autoParamsForCoordinates(a.lat, a.lng)
            switch (params, a.params) {
            case (nil, nil):
                continue
            case let (p?, expected?):
                expected.assertMatches(p, context)
            default:
                XCTFail("\(context): expected \(a.params == nil ? "nil" : "params") got \(params == nil ? "nil" : "params")")
            }
        }
    }

    func testTimingsByCoordinatesAuto() throws {
        XCTAssertEqual(Self.file.timingsByCoordinatesAuto.count, 6)
        let service = PrayerTimesService(directory: directory)
        for t in Self.file.timingsByCoordinatesAuto {
            let context = "timingsByCoordinatesAuto(\(t.lat), \(t.lng), \(t.date))"
            let result = try service.timingsByCoordinatesAuto(t.lat, t.lng, date: GeocodingFixtures.date(t.date))
            guard let expected = t.raw else {
                XCTAssertNil(result, context)
                continue
            }
            guard let result = result else {
                XCTFail("\(context): expected a result")
                continue
            }
            for prayer in Prayer.allCases {
                assertSame(result.timings.raw[prayer], expected[prayer.key] ?? nil, "\(context) \(prayer.key)")
            }
        }
    }
}
