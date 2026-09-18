import XCTest
@testable import IslamicKitPlus

final class BundledCityGeocoderTests: XCTestCase {
    private let geocoder = BundledCityGeocoder()

    func testResolvesLondonGB() throws {
        let city = try XCTUnwrap(geocoder.resolve("London", country: "GB"))
        XCTAssertEqual(city.coordinates.latitude, 51.5, accuracy: 0.1)
        XCTAssertEqual(city.country, "GB")
    }

    func testResolvesFreeTextAddressBySegment() {
        let city = geocoder.resolve("Trafalgar Square, London, UK")
        XCTAssertEqual(city?.name, "London")
    }

    func testCountryNameAliasWorks() {
        let city = geocoder.resolve("Cairo", country: "Egypt")
        XCTAssertEqual(city?.country, "EG")
    }

    func testDatasetShape() {
        XCTAssertEqual(CityDataset.records.count, 103)
        XCTAssertEqual(CityDataset.countryAliases.count, 23)
        XCTAssertEqual(CountryIsoMap.idToIso.count, 251)
        XCTAssertEqual(CountryIsoMap.fractionalZoneOffsetMinutes.count, 18)
        XCTAssertEqual(CountryIsoMap.isoToId["EG"], CountryIsoMap.idToIso.first { $0.value == "EG" }?.key)
    }

    func testEmptyQueryMatchesNothing() {
        XCTAssertTrue(geocoder.search("   ").isEmpty)
    }

    func testStateFilter() {
        XCTAssertEqual(geocoder.resolve("London", state: "England")?.name, "London")
        XCTAssertNil(geocoder.resolve("London", state: "Ontario"))
    }

    func testCityCarriesStandardOffset() {
        XCTAssertEqual(geocoder.resolve("Paris", country: "FR")?.utcOffset, UTCOffset(hours: 1))
    }

    // MARK: Matching helpers (shared with the SQLite geocoder)

    func testNormalizeCollapsesWhitespaceAndLowercases() {
        XCTAssertEqual(GeocoderMatching.normalize("  New\t\tYork \u{00A0} City "), "new york city")
        XCTAssertEqual(GeocoderMatching.normalize("\u{FEFF}Türkiye"), "türkiye")
    }

    func testCandidatesIncludeSegments() {
        XCTAssertEqual(GeocoderMatching.candidates("Trafalgar Square, London, UK"),
                       ["trafalgar square, london, uk", "trafalgar square", "london", "uk"])
        XCTAssertEqual(GeocoderMatching.candidates("London, london"), ["london, london", "london"])
        XCTAssertEqual(GeocoderMatching.candidates(" , "), [","]) // the comma itself survives normalisation
    }

    func testScoreOrdering() {
        XCTAssertEqual(GeocoderMatching.score("london", ["london"]), 0)
        XCTAssertEqual(GeocoderMatching.score("londonderry", ["london"]), 1)
        XCTAssertEqual(GeocoderMatching.score("london", ["greater london"]), 2)
        XCTAssertEqual(GeocoderMatching.score("greater london", ["london"]), 3)
        XCTAssertNil(GeocoderMatching.score("paris", ["london"]))
        XCTAssertEqual(GeocoderMatching.score("greater london", ["x", "london", "greater london"]), 0)
    }

    func testResolveCountry() {
        XCTAssertNil(GeocoderMatching.resolveCountry(nil))
        XCTAssertEqual(GeocoderMatching.resolveCountry("gb"), "GB")
        XCTAssertEqual(GeocoderMatching.resolveCountry("uk"), "UK") // 2-char input is never aliased
        XCTAssertEqual(GeocoderMatching.resolveCountry("United Kingdom"), "GB")
        XCTAssertEqual(GeocoderMatching.resolveCountry("Narnia"), "NARNIA")
    }

    func testPlaceRankAndOffsetMinutes() {
        XCTAssertEqual(GeocoderMatching.placeRank("PPLC"), 0)
        XCTAssertEqual(GeocoderMatching.placeRank("PPL"), 5)
        XCTAssertEqual(GeocoderMatching.placeRank(nil), 6)
        XCTAssertEqual(GeocoderMatching.offsetMinutes(timeZoneId: "Asia/Tehran", hours: 3), 210)
        XCTAssertEqual(GeocoderMatching.offsetMinutes(timeZoneId: "Africa/Cairo", hours: 2), 120)
        XCTAssertEqual(GeocoderMatching.offsetMinutes(timeZoneId: nil, hours: nil), 0)
    }
}
