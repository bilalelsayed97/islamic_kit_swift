import XCTest
@testable import IslamicKitPlusGeocoding

/// Port of the Dart `test/city_directory_test.dart`.
final class CityDirectoryTests: XCTestCase {
    private var directory: SqliteCityDirectory { TestDatabase.directory }

    private func single(_ query: String, file: StaticString = #filePath, line: UInt = #line) throws -> CountryInfo {
        let results = directory.countries(query: query)
        XCTAssertEqual(results.count, 1, "countries(query: \(query))", file: file, line: line)
        return try XCTUnwrap(results.first, file: file, line: line)
    }

    func testListsEveryCountryWithIsoCodeAndBothNames() {
        let countries = directory.countries()
        XCTAssertEqual(countries.count, 251)
        XCTAssertTrue(countries.allSatisfy { $0.isoCode.count == 2 })
        XCTAssertTrue(countries.allSatisfy { !$0.nameEn.isEmpty })
        XCTAssertTrue(countries.allSatisfy { !$0.nameAr.isEmpty })
    }

    func testFiltersCountriesByEitherLanguage() throws {
        XCTAssertEqual(try single("Egypt").isoCode, "EG")
        XCTAssertEqual(try single("مصر").isoCode, "EG")
    }

    func testExposesTheRecommendedCalculationMethod() throws {
        let egypt = try single("Egypt")
        XCTAssertEqual(egypt.calculationMethodId, 5)
        XCTAssertEqual(egypt.calculationMethod, .egypt)
    }

    func testResolvesTheDatabaseMethodIdsThatCollideWithAladhanIds() throws {
        func methodFor(_ iso: String) throws -> CalculationMethod? {
            try XCTUnwrap(directory.country(try XCTUnwrap(CountryIsoMap.isoToId[iso]))).calculationMethod
        }
        // The database numbers its authorities independently of aladhan: id 7
        // is Kuwait here but Tehran there, id 9 is Singapore here but Kuwait
        // there.
        XCTAssertEqual(try methodFor("KW"), .kuwait)
        XCTAssertEqual(try methodFor("QA"), .qatar)
        XCTAssertEqual(try methodFor("SG"), .singapore)
        XCTAssertEqual(try methodFor("SA"), .makkah)
        XCTAssertEqual(try methodFor("TR"), .turkey)
        XCTAssertEqual(try methodFor("CA"), .canada)
        XCTAssertEqual(try methodFor("IR"), .tehran)
        XCTAssertEqual(try methodFor("OM"), .oman)
        XCTAssertEqual(try methodFor("DE"), .munich)
        XCTAssertEqual(try methodFor("LU"), .luxembourg)
        // The default bucket the database assigns to most of the world.
        XCTAssertEqual(try methodFor("GB"), .mwl)
    }

    func testEveryCountryResolvesToAKnownMethod() {
        let unresolved = directory.countries().filter { $0.calculationMethod == nil }
        XCTAssertTrue(unresolved.isEmpty, "\(unresolved)")
    }

    func testCitiesCarryTheirCountrysRecommendedMethod() {
        XCTAssertEqual(directory.nearestCity(21.4225, 39.8262)?.calculationMethod, .makkah)
    }

    func testOrdersACountrysCitiesByProminenceCapitalFirst() throws {
        let egypt = try single("Egypt")
        let cities = directory.citiesInCountry(egypt.id, limit: 1)
        XCTAssertEqual(cities.count, 1)
        XCTAssertEqual(cities.first?.nameEn, "Cairo")
        XCTAssertEqual(cities.first?.nameAr, "القاهرة")
        XCTAssertEqual(cities.first?.isoCode, "EG")
    }

    func testPagesThroughACountrysCitiesWithoutRepeating() throws {
        let egypt = try single("Egypt")
        let first = directory.citiesInCountry(egypt.id, limit: 10)
        let second = directory.citiesInCountry(egypt.id, query: nil, limit: 10, offset: 10)
        XCTAssertEqual(first.count, 10)
        XCTAssertEqual(second.count, 10)
        XCTAssertTrue(Set(first).intersection(Set(second)).isEmpty)
    }

    func testSearchMatchesArabicAndEnglishNames() {
        XCTAssertEqual(directory.searchCities(query: "القاهرة", limit: 1).first?.nameEn, "Cairo")
        XCTAssertEqual(directory.searchCities(query: "Cairo", limit: 1).first?.nameAr, "القاهرة")
    }

    func testReverseGeocodingAnswersTheCityNotTheNeighbourhood() {
        let city = directory.nearestCity(30.06263, 31.24967)
        XCTAssertEqual(city?.nameEn, "Cairo")
        XCTAssertEqual(city?.isoCode, "EG")
        XCTAssertEqual(city?.timeZoneId, "Africa/Cairo")
    }

    func testReverseGeocodingResolvesMecca() {
        let city = directory.nearestCity(21.4225, 39.8262)
        XCTAssertEqual(city?.nameAr, "مكة المكرمة")
        XCTAssertEqual(city?.isoCode, "SA")
    }

    func testReverseGeocodingFallsBackWhenTheLocalBoxIsEmpty() {
        // Mid-Atlantic: no populated place for thousands of kilometres.
        XCTAssertNotNil(directory.nearestCity(0, -30))
    }

    func testSingleZoneCountriesOfferExactlyOneTimezone() throws {
        let egypt = try single("Egypt")
        let zones = directory.timeZonesForCountry(egypt.id)
        XCTAssertEqual(zones.count, 1)
        XCTAssertEqual(zones.first?.ianaId, "Africa/Cairo")
        XCTAssertEqual(zones.first?.nameAr?.isEmpty, false)
    }

    func testMultiZoneCountriesOfferEveryRealZone() throws {
        let us = try XCTUnwrap(directory.countries(query: "United States").first { $0.isoCode == "US" })
        let zones = directory.timeZonesForCountry(us.id)
        XCTAssertGreaterThanOrEqual(zones.count, 8)
        let ids = Set(zones.map(\.ianaId))
        XCTAssertTrue(ids.isSuperset(of: ["America/New_York", "America/Los_Angeles"]), "\(ids)")
    }

    func testEveryOfferedTimezoneCarriesAnArabicLabel() {
        for country in directory.countries() {
            for zone in directory.timeZonesForCountry(country.id) {
                XCTAssertNotNil(zone.nameAr, zone.ianaId)
            }
        }
    }

    func testIsoMapRoundTripsInBothDirections() throws {
        XCTAssertEqual(CountryIsoMap.idToIso.count, 251)
        let egypt = try XCTUnwrap(CountryIsoMap.isoToId["EG"])
        XCTAssertEqual(CountryIsoMap.idToIso[egypt], "EG")
    }

    // MARK: Swift-only

    func testUnknownCountryIdIsNil() {
        XCTAssertNil(directory.country(999))
        XCTAssertNil(directory.country(103)) // absent from the database
        XCTAssertTrue(directory.citiesInCountry(999).isEmpty)
        XCTAssertTrue(directory.timeZonesForCountry(999).isEmpty)
    }

    func testServiceUsesTheDirectoryForAutomaticParameters() throws {
        let service = PrayerTimesService(directory: directory)
        let params = try XCTUnwrap(service.autoParamsForCoordinates(30.06263, 31.24967))
        XCTAssertEqual(params.method, .egypt)
        XCTAssertEqual(params.utcOffset, UTCOffset(hours: 2))
        XCTAssertEqual(params.timezoneName, "Africa/Cairo")
        XCTAssertEqual(params.school, .standard)

        let tehran = try XCTUnwrap(service.autoParamsForCoordinates(35.6892, 51.3890))
        XCTAssertEqual(tehran.method, .tehran)
        XCTAssertEqual(tehran.utcOffset, UTCOffset(hours: 3, minutes: 30))

        XCTAssertThrowsError(try PrayerTimesService().autoParamsForCoordinates(0, 0)) { error in
            XCTAssertEqual(error as? IslamicKitError, .directoryRequired)
        }
    }
}
