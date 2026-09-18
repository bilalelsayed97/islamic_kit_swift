import XCTest
@testable import IslamicKitPlus

/// `methods.json` and `aladhan.json`: every aladhan envelope compared as the
/// exact `jsonEncode` string.
final class ConformanceAladhanTests: XCTestCase {
    private struct MethodsFile: Decodable {
        let json: String
    }

    private struct AladhanFile: Decodable {
        struct Input: Decodable {
            struct Point: Decodable {
                let lat: Double
                let lng: Double
            }

            let lat: Double
            let lng: Double
            let params: FixtureParams
            let year: Int
            let month: Int
            let day: String
            let nextPrayer: String
            let qibla: Point
        }

        let input: Input
        let calendar: String
        let calendarIso: String
        let annual: String
        let nextPrayer: String
        let qibla: String
        let methods: String
    }

    func testMethodsJson() throws {
        let file: MethodsFile = try ConformanceFixtures.load("methods")
        XCTAssertEqual(methodsAladhanJson().serialized(), file.json)
    }

    func testEnvelopes() throws {
        let file: AladhanFile = try ConformanceFixtures.load("aladhan")
        let service = PrayerTimesService()
        let input = file.input
        let coordinates = Coordinates(input.lat, input.lng)
        let params = input.params.toCalculationParameters()

        let month = try service.monthlyCalendar(input.year, input.month, coordinates, params)
        let year = try service.annualCalendar(input.year, coordinates, params)
        let day = try service.timings(ConformanceFixtures.date(input.day), coordinates, params)
        let qibla = service.qibla(Coordinates(input.qibla.lat, input.qibla.lng))
        let prayer = try XCTUnwrap(Prayer(key: input.nextPrayer))

        assertSame(calendarAladhanJson(month).serialized(), file.calendar, "calendar")
        assertSame(calendarAladhanJson(month, format: .iso8601).serialized(), file.calendarIso, "calendarIso")
        assertSame(annualCalendarAladhanJson(year).serialized(), file.annual, "annual")
        assertSame(nextPrayerAladhanJson(day, prayer).serialized(), file.nextPrayer, "nextPrayer")
        assertSame(qiblaAladhanJson(qibla).serialized(), file.qibla, "qibla")
        assertSame(methodsAladhanJson().serialized(), file.methods, "methods")
    }
}
