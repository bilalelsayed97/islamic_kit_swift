import XCTest
@testable import IslamicKitPlusGeocoding

/// `geocoder_sqlite.json`: `SqliteCityGeocoder` searches against the bundled
/// database. Result sets are compared as multisets; the first result is
/// pinned only when the fixture flags its `(score, rank)` as unique.
final class ConformanceSqliteGeocoderTests: XCTestCase {
    private struct File: Decodable {
        let cases: [Case]
    }

    private struct Case: Decodable {
        let query: String
        let country: String?
        let results: [GeocoderResultKey]
        let firstUnique: Bool
    }

    func testSearches() throws {
        let file: File = try GeocodingFixtures.load("geocoder_sqlite")
        XCTAssertEqual(file.cases.count, 30)
        for c in file.cases {
            let context = "search(\"\(c.query)\", country: \(c.country ?? "nil"))"
            let keys = TestDatabase.geocoder.search(c.query, country: c.country).map(GeocoderResultKey.init)
            assertSame(keys.count, c.results.count, "\(context) count")
            assertSame(multiset(keys), multiset(c.results), "\(context) result set")
            if c.firstUnique {
                assertSame(keys.first, c.results.first, "\(context) first result")
            }
        }
    }
}
