import XCTest
import IslamicKitPlus

final class LocationDefaultsTests: XCTestCase {
    func testMethodByCountry() {
        XCTAssertEqual(LocationDefaults.methodForCountry("US"), .isna)
        XCTAssertEqual(LocationDefaults.methodForCountry("SA"), .makkah)
        XCTAssertEqual(LocationDefaults.methodForCountry("PK"), .karachi)
        XCTAssertEqual(LocationDefaults.methodForCountry("gb"), .mwl)
        XCTAssertEqual(LocationDefaults.methodForCountry("XX"), .mwl)
    }

    func testSchoolByCountry() {
        XCTAssertEqual(LocationDefaults.schoolForCountry("PK"), .hanafi)
        XCTAssertEqual(LocationDefaults.schoolForCountry("tr"), .hanafi)
        XCTAssertEqual(LocationDefaults.schoolForCountry("GB"), .standard)
    }

    // MARK: Automatic per-location settings

    private let service = PrayerTimesService() // curated geocoder (has Cairo, EG)

    func testRecommendedParamsPicksMethodAndSchool() {
        let p = service.recommendedParams("EG", utcOffset: UTCOffset(hours: 2))
        XCTAssertEqual(p.method, .egypt)
        XCTAssertEqual(p.school, .standard)
        XCTAssertEqual(p.utcOffset, UTCOffset(hours: 2))
        XCTAssertNil(p.timezoneName)
    }

    func testTimingsByCityAutoInfersMethodAndOffset() throws {
        let result = try service.timingsByCityAuto("Cairo", date: CivilDate(year: 2024, month: 4, day: 24), country: "EG")
        XCTAssertEqual(result.meta.method, .egypt)
        XCTAssertEqual(result.meta.coordinates.latitude, 30.04, accuracy: 0.1)
        XCTAssertNotEqual(result.formatted(.fajr), invalidTime)
        XCTAssertEqual(result.timings.utcOffset, UTCOffset(hours: 2))
    }

    func testAutoParamsForCity() throws {
        let city = try XCTUnwrap(BundledCityGeocoder().resolve("Karachi", country: "PK"))
        let p = service.autoParamsForCity(city)
        XCTAssertEqual(p.method, .karachi)
        XCTAssertEqual(p.school, .hanafi)
        XCTAssertEqual(p.utcOffset, UTCOffset(hours: 5))
    }
}
