import XCTest
@testable import IslamicKitPlus

final class CivilDateTests: XCTestCase {
    func testNormalisesDayOverflowLikeDart() {
        XCTAssertEqual(CivilDate(year: 2014, month: 2, day: 30), CivilDate(year: 2014, month: 3, day: 2))
        XCTAssertEqual(CivilDate(year: 2014, month: 4, day: 31), CivilDate(year: 2014, month: 5, day: 1))
        XCTAssertEqual(CivilDate(year: 2014, month: 5, day: 0), CivilDate(year: 2014, month: 4, day: 30))
        XCTAssertEqual(CivilDate(year: 2014, month: 3, day: -1), CivilDate(year: 2014, month: 2, day: 27))
        XCTAssertEqual(CivilDate(year: 2014, month: 12, day: 32), CivilDate(year: 2015, month: 1, day: 1))
    }

    func testNormalisesMonthOverflowFirst() {
        XCTAssertEqual(CivilDate(year: 2014, month: 13, day: 1), CivilDate(year: 2015, month: 1, day: 1))
        XCTAssertEqual(CivilDate(year: 2014, month: 0, day: 1), CivilDate(year: 2013, month: 12, day: 1))
        XCTAssertEqual(CivilDate(year: 2014, month: 3, day: 31).addingMonths(11), CivilDate(year: 2015, month: 3, day: 3))
        XCTAssertEqual(CivilDate(year: 2014, month: 1, day: 31).addingMonths(1), CivilDate(year: 2014, month: 3, day: 3))
        // DateTime(year, month + 1, 0).day — days in month.
        XCTAssertEqual(CivilDate(year: 2014, month: 5, day: 0).day, 30)
        XCTAssertEqual(CivilDate(year: 2024, month: 3, day: 0).day, 29)
        XCTAssertEqual(CivilDate(year: 2014, month: 13, day: 0).day, 31)
    }

    func testJulianDayNumber() {
        XCTAssertEqual(CivilDate(year: 2000, month: 1, day: 1).julianDayNumber, 2451545)
        XCTAssertEqual(CivilDate(year: 1970, month: 1, day: 1).julianDayNumber, 2440588)
        XCTAssertEqual(CivilDate(year: 1970, month: 1, day: 1).unixMidnightSeconds, 0)
        XCTAssertEqual(CivilDate(year: 2014, month: 4, day: 24).unixMidnightSeconds, 1398297600)
        XCTAssertEqual(CivilDate(julianDayNumber: 2451545), CivilDate(year: 2000, month: 1, day: 1))
        XCTAssertEqual(CivilDate(year: 1600, month: 2, day: 29).addingDays(1), CivilDate(year: 1600, month: 3, day: 1))
    }

    func testIsoWeekday() {
        XCTAssertEqual(CivilDate(year: 2000, month: 1, day: 1).isoWeekday, 6) // Saturday
        XCTAssertEqual(CivilDate(year: 2014, month: 4, day: 24).isoWeekday, 4) // Thursday
        XCTAssertEqual(CivilDate(year: 2024, month: 12, day: 15).isoWeekday, 7) // Sunday
        XCTAssertEqual(CivilDate(year: 2025, month: 2, day: 17).isoWeekday, 1) // Monday
    }

    func testRoundTripAcrossCenturies() {
        var date = CivilDate(year: 1890, month: 1, day: 1)
        let end = CivilDate(year: 2110, month: 12, day: 31)
        var jdn = date.julianDayNumber
        while date <= end {
            XCTAssertEqual(date.julianDayNumber, jdn)
            XCTAssertEqual(CivilDate(julianDayNumber: jdn), date)
            XCTAssertTrue(date.day >= 1 && date.day <= date.daysInMonth)
            date = date.addingDays(1)
            jdn += 1
        }
    }

    func testDayOfYearAndLeapYears() {
        XCTAssertEqual(CivilDate(year: 2024, month: 12, day: 31).dayOfYear, 366)
        XCTAssertEqual(CivilDate(year: 2023, month: 12, day: 31).dayOfYear, 365)
        XCTAssertEqual(CivilDate(year: 2024, month: 1, day: 1).dayOfYear, 1)
        XCTAssertTrue(CivilDate.isLeapYear(2000))
        XCTAssertFalse(CivilDate.isLeapYear(1900))
        XCTAssertTrue(CivilDate.isLeapYear(2024))
    }

    func testIsoStringAndComparable() {
        XCTAssertEqual(CivilDate(year: 2014, month: 4, day: 24).isoString, "2014-04-24")
        XCTAssertEqual(CivilDate(year: 800, month: 1, day: 5).isoString, "0800-01-05")
        XCTAssertLessThan(CivilDate(year: 2014, month: 4, day: 24), CivilDate(year: 2014, month: 4, day: 25))
        XCTAssertLessThan(CivilDateTime(year: 2014, month: 4, day: 24, hour: 13, minute: 30),
                          CivilDateTime(year: 2014, month: 4, day: 24, hour: 13, minute: 31))
        XCTAssertEqual(CivilDateTime(year: 2014, month: 4, day: 24, hour: 13, minute: 30).fractionalHours, 13.5)
    }

    func testFoundationConveniences() {
        let utc = TimeZone(identifier: "UTC")!
        let date = Date(timeIntervalSince1970: 1398297600 + 3600 * 5) // 2014-04-24 05:00 UTC
        XCTAssertEqual(CivilDate(date, in: utc), CivilDate(year: 2014, month: 4, day: 24))
        XCTAssertEqual(CivilDateTime(date, in: utc).hour, 5)
        XCTAssertEqual(CivilDate(year: 2014, month: 4, day: 24).utcMidnight.timeIntervalSince1970, 1398297600)
    }

    func testUTCOffset() {
        XCTAssertEqual(UTCOffset(hours: 5, minutes: 30).isoString, "+05:30")
        XCTAssertEqual(UTCOffset(hours: -3, minutes: -30).isoString, "-03:30")
        XCTAssertEqual(UTCOffset(hours: -3, minutes: -30).hours, -3)
        XCTAssertEqual(UTCOffset(hours: -3, minutes: -30).minutesPart, 30)
        XCTAssertEqual(UTCOffset(hours: -3, minutes: -30).abs(), UTCOffset(hours: 3, minutes: 30))
        XCTAssertTrue(UTCOffset(seconds: -1).isNegative)
        XCTAssertEqual(UTCOffset.zero.isoString, "+00:00")
        XCTAssertEqual(UTCOffset(iso: "+05:30"), UTCOffset(hours: 5, minutes: 30))
        XCTAssertEqual(UTCOffset(iso: "-0330"), UTCOffset(hours: -3, minutes: -30))
        XCTAssertEqual(UTCOffset(iso: "Z"), .zero)
        XCTAssertNil(UTCOffset(iso: "5:30"))
        XCTAssertEqual(UTCOffset(timeZone: TimeZone(identifier: "Asia/Kolkata")!, at: Date(timeIntervalSince1970: 0)).seconds, 19800)
        XCTAssertEqual(UTCOffset(timeZone: TimeZone(identifier: "Europe/London")!,
                                 on: CivilDate(year: 2014, month: 4, day: 24)).seconds, 3600)
    }

    func testIntegerMath() {
        XCTAssertEqual(IntegerMath.floorDiv(-7, 2), -4)
        XCTAssertEqual(IntegerMath.floorDiv(7, 2), 3)
        XCTAssertEqual(IntegerMath.floorMod(-7, 60), 53)
        XCTAssertEqual(IntegerMath.floorMod(7, 60), 7)
        XCTAssertEqual(IntegerMath.floorMod(-60, 60), 0)
        XCTAssertEqual(IntegerMath.javaRound(-0.5), 0)
        XCTAssertEqual(IntegerMath.javaRound(0.5), 1)
    }
}
