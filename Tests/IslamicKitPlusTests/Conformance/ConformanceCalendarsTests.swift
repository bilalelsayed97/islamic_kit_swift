import XCTest
@testable import IslamicKitPlus

/// `calendars.json`: monthly, annual, range and Hijri calendars plus the
/// invalid-range cases.
final class ConformanceCalendarsTests: XCTestCase {
    private struct File: Decodable {
        let cases: [Case]
    }

    private struct Day: Decodable {
        let date: String
        let hijri: String
        let raw: FixtureRaw
    }

    private struct MonthSummary: Decodable {
        let count: Int
        let first: Day
        let last: Day
    }

    private struct Case: Decodable {
        let kind: String
        let lat: Double
        let lng: Double
        let params: FixtureParams
        // monthly / annual
        let year: Int?
        let month: Int?
        let days: [Day]?
        let months: [String: MonthSummary]?
        // range / rangeError
        let start: String?
        let end: String?
        let count: Int?
        let first: Day?
        let last: Day?
        let error: String?
        // hijriMonthly / hijriAnnual
        let hijriYear: Int?
        let hijriMonth: Int?
    }

    private let service = PrayerTimesService()

    func testEveryCalendarKind() throws {
        let file: File = try ConformanceFixtures.load("calendars")
        XCTAssertEqual(file.cases.count, 10)
        for (index, c) in file.cases.enumerated() {
            let id = "case[\(index)] \(c.kind)"
            let coordinates = Coordinates(c.lat, c.lng)
            let params = c.params.toCalculationParameters()
            switch c.kind {
            case "monthly":
                let days = try service.monthlyCalendar(c.year!, c.month!, coordinates, params)
                assertDays(days, c.days!, id)
            case "annual":
                let months = try service.annualCalendar(c.year!, coordinates, params)
                assertMonths(months, c.months!, id)
            case "range":
                let days = try service.rangeCalendar(
                    ConformanceFixtures.date(c.start!), ConformanceFixtures.date(c.end!), coordinates, params
                )
                assertSame(days.count, c.count!, "\(id) count")
                assertDay(days.first!, c.first!, "\(id) first")
                assertDay(days.last!, c.last!, "\(id) last")
            case "rangeError":
                XCTAssertEqual(c.error, "ArgumentError", id)
                XCTAssertThrowsError(
                    try service.rangeCalendar(
                        ConformanceFixtures.date(c.start!), ConformanceFixtures.date(c.end!), coordinates, params
                    ),
                    id
                ) { error in
                    guard case IslamicKitError.invalidDateRange = error else {
                        return XCTFail("\(id): expected invalidDateRange, got \(error)")
                    }
                }
            case "hijriMonthly":
                let days = try service.monthlyHijriCalendar(c.hijriYear!, c.hijriMonth!, coordinates, params)
                assertDays(days, c.days!, "\(id) \(c.params.calendarMethod)")
            case "hijriAnnual":
                let months = try service.annualHijriCalendar(c.hijriYear!, coordinates, params)
                assertMonths(months, c.months!, id)
            default:
                XCTFail("\(id): unknown kind")
            }
        }
    }

    private func assertDay(_ r: PrayerResult, _ d: Day, _ context: String) {
        assertSame(r.date.gregorian.formatted, d.date, "\(context) date")
        assertSame(r.date.hijri.formatted, d.hijri, "\(context) hijri")
        assertRawEqual(r.timings.raw, d.raw, context)
    }

    private func assertDays(_ actual: [PrayerResult], _ expected: [Day], _ context: String) {
        assertSame(actual.count, expected.count, "\(context) count")
        for (i, (r, d)) in zip(actual, expected).enumerated() {
            assertDay(r, d, "\(context) day[\(i)]")
        }
    }

    private func assertMonths(_ actual: [Int: [PrayerResult]], _ expected: [String: MonthSummary], _ context: String) {
        assertSame(actual.count, expected.count, "\(context) month count")
        for (key, summary) in expected {
            guard let days = actual[Int(key)!] else {
                XCTFail("\(context): month \(key) missing")
                continue
            }
            assertSame(days.count, summary.count, "\(context) month \(key) count")
            assertDay(days.first!, summary.first, "\(context) month \(key) first")
            assertDay(days.last!, summary.last, "\(context) month \(key) last")
        }
    }
}
