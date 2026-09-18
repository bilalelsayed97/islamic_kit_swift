import XCTest
@testable import IslamicKitPlusGeocoding

/// Port of the `SqliteCityGeocoder (bundled city database)` group of the
/// Dart `test/geocoder_test.dart`.
final class SqliteCityGeocoderTests: XCTestCase {
    private var geocoder: SqliteCityGeocoder { TestDatabase.geocoder }

    func testResolvesLondonGBWithArabicName() throws {
        let city = try XCTUnwrap(geocoder.resolve("London", country: "GB"))
        XCTAssertEqual(city.coordinates.latitude, 51.50853, accuracy: 0.01)
        XCTAssertEqual(city.coordinates.longitude, -0.12574, accuracy: 0.01)
        XCTAssertNotNil(city.nameAr)
        XCTAssertEqual(city.country, "GB")
    }

    func testResolvesMecca() throws {
        let city = try XCTUnwrap(geocoder.resolve("Mecca"))
        XCTAssertEqual(city.coordinates.latitude, 21.42, accuracy: 0.2)
    }

    func testCountryNameAliasResolvesToIsoCode() {
        XCTAssertEqual(geocoder.resolve("Cairo", country: "Egypt")?.country, "EG")
    }

    func testAppliesHalfHourOffsetsThatTheHourColumnTruncates() {
        XCTAssertEqual(geocoder.resolve("Tehran", country: "IR")?.utcOffset, UTCOffset(hours: 3, minutes: 30))
        XCTAssertEqual(geocoder.resolve("Delhi", country: "IN")?.utcOffset, UTCOffset(hours: 5, minutes: 30))
    }

    func testPrefersTheCapitalOverSameNamedLesserSettlements() throws {
        let city = try XCTUnwrap(geocoder.resolve("Paris", country: "FR"))
        XCTAssertEqual(city.coordinates.latitude, 48.85, accuracy: 0.2)
    }

    func testUnknownCountryCodeMatchesNothing() {
        XCTAssertTrue(geocoder.search("London", country: "ZZ").isEmpty)
    }

    // MARK: Swift-only

    func testEmptyQueryMatchesNothing() {
        XCTAssertTrue(geocoder.search("   ").isEmpty)
        XCTAssertTrue(geocoder.search("", country: "GB").isEmpty)
    }

    func testStateIsIgnoredAndAlwaysNil() {
        let withState = geocoder.search("London", country: "GB", state: "Ontario")
        XCTAssertEqual(withState.map(\.name), geocoder.search("London", country: "GB").map(\.name))
        XCTAssertTrue(withState.allSatisfy { $0.state == nil })
    }

    func testArabicQueryMatches() {
        XCTAssertEqual(geocoder.resolve("القاهرة", country: "EG")?.name, "Cairo")
    }
}
