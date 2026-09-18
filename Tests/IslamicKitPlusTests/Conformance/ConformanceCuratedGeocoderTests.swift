import XCTest
@testable import IslamicKitPlus

/// A geocoder result reduced to the fields the fixtures record, so result
/// sets can be compared as multisets (Dart's sort is unstable among ties).
struct GeocoderResultKey: Hashable, CustomStringConvertible, Decodable {
    let name: String
    let nameAr: String?
    let country: String
    let state: String?
    let lat: Double
    let lng: Double
    let offsetMinutes: Int

    init(_ city: City) {
        name = city.name
        nameAr = city.nameAr
        country = city.country
        state = city.state
        lat = city.coordinates.latitude
        lng = city.coordinates.longitude
        offsetMinutes = city.utcOffset.totalMinutes
    }

    var description: String {
        "\(name)/\(nameAr ?? "-")/\(country)/\(state ?? "-")/\(lat)/\(lng)/\(offsetMinutes)"
    }
}

/// Asserts `actual` and `expected` hold the same results (as a multiset) and,
/// when the fixture flags the best score as unique, the same first result.
func assertGeocoderResults(
    _ actual: [City],
    _ expected: [GeocoderResultKey],
    firstUnique: Bool,
    _ context: @autoclosure () -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let keys = actual.map(GeocoderResultKey.init)
    let c = context()
    assertSame(keys.count, expected.count, "\(c) count", file: file, line: line)
    assertSame(multiset(keys), multiset(expected), "\(c) result set", file: file, line: line)
    if firstUnique {
        assertSame(keys.first, expected.first, "\(c) first result", file: file, line: line)
    }
}

func multiset<T: Hashable>(_ items: [T]) -> [T: Int] {
    var out = [T: Int]()
    for item in items { out[item, default: 0] += 1 }
    return out
}

/// `geocoder_curated.json`: `BundledCityGeocoder` searches.
final class ConformanceCuratedGeocoderTests: XCTestCase {
    private struct File: Decodable {
        let cases: [Case]
    }

    private struct Case: Decodable {
        let query: String
        let country: String?
        let state: String?
        let results: [GeocoderResultKey]
        let firstUnique: Bool
    }

    func testSearches() throws {
        let file: File = try ConformanceFixtures.load("geocoder_curated")
        XCTAssertEqual(file.cases.count, 30)
        let geocoder = BundledCityGeocoder()
        for c in file.cases {
            let results = geocoder.search(c.query, country: c.country, state: c.state)
            assertGeocoderResults(
                results, c.results, firstUnique: c.firstUnique,
                "search(\"\(c.query)\", country: \(c.country ?? "nil"), state: \(c.state ?? "nil"))"
            )
        }
    }
}
