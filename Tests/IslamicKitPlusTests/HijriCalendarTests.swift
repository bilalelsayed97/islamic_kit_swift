import XCTest
import IslamicKitPlus

final class HijriCalendarTests: XCTestCase {
    private let factory = HijriConverterFactory()
    private let date = CivilDate(year: 2025, month: 2, day: 14)

    private func assertYMD(
        _ h: HijriDate, _ year: Int, _ month: Int, _ day: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual([h.year, h.month, h.day], [year, month, day], file: file, line: line)
    }

    // MARK: Gregorian -> Hijri for 14-02-2025

    func testUmmAlQura() throws {
        let h = try factory.create(.uaq).fromGregorian(date)
        assertYMD(h, 1446, 8, 15)
        XCTAssertEqual(h.monthLength, 29)
        XCTAssertEqual(h.monthEn, "Sha'ban")
        XCTAssertEqual(h.weekdayEn, "Friday")
        XCTAssertEqual(h.weekdayAr, "الجمعة")
        XCTAssertEqual(h.formatted, "15-08-1446")
    }

    func testHjcosaMatchesUmmAlQuraWhenUnadjusted() throws {
        let h = try factory.create(.hjcosa).fromGregorian(date)
        assertYMD(h, 1446, 8, 15)
    }

    func testDiyanet() throws {
        let h = try factory.create(.diyanet).fromGregorian(date)
        assertYMD(h, 1446, 8, 16)
        XCTAssertEqual(h.monthLength, 30)
    }

    func testMathematical() throws {
        let h = try factory.create(.mathematical).fromGregorian(date)
        assertYMD(h, 1446, 8, 15)
        XCTAssertEqual(h.monthLength, 30)
    }

    func testMathematicalHonoursPlusOneAdjustment() throws {
        let h = try factory.create(.mathematical).fromGregorian(date, adjustment: 1)
        XCTAssertEqual(h.day, 16)
    }

    // MARK: Hijri -> Gregorian round trips

    func testUmmAlQuraRoundTrip() throws {
        let g = try factory.create(.uaq).toGregorian(year: 1446, month: 8, day: 15)
        XCTAssertEqual(g, CivilDate(year: 2025, month: 2, day: 14))
    }

    func testMathematicalMinusOneAdjustment() throws {
        let g = try factory.create(.mathematical).toGregorian(year: 1446, month: 8, day: 15, adjustment: -1)
        XCTAssertEqual(g, CivilDate(year: 2025, month: 2, day: 13))
    }

    // MARK: HJCoSA lunar-sighting overrides

    func testSightingOverrideForward() throws {
        let h = try factory.create(.hjcosa).fromGregorian(CivilDate(year: 2018, month: 5, day: 17))
        assertYMD(h, 1439, 9, 1)
        XCTAssertEqual(h.holidays, ["1st Day of Ramadan"])
    }

    func testSightingOverrideBackward() throws {
        let g = try factory.create(.hjcosa).toGregorian(year: 1439, month: 9, day: 1)
        XCTAssertEqual(g, CivilDate(year: 2018, month: 5, day: 17))
    }

    // MARK: Validity ranges throw

    func testUmmAlQuraHijriBeforeRange() {
        XCTAssertThrowsError(try factory.create(.uaq).toGregorian(year: 1200, month: 8, day: 15)) { error in
            XCTAssertEqual(error as? IslamicKitError,
                           .hijriDateOutOfRange("Hijri date out of range for UAQ ((1356, 1, 1) .. (1500, 12, 30))."))
        }
    }

    func testUmmAlQuraGregorianBeforeRange() {
        XCTAssertThrowsError(try factory.create(.uaq).fromGregorian(CivilDate(year: 1800, month: 1, day: 1))) { error in
            XCTAssertEqual(error as? IslamicKitError,
                           .gregorianDateOutOfRange("Gregorian date out of range for UAQ ((1937, 3, 14) .. (2077, 11, 16))."))
        }
    }

    func testTableEdges() throws {
        let first = try factory.create(.uaq).fromGregorian(CivilDate(year: 1937, month: 3, day: 14))
        assertYMD(first, 1356, 1, 1)
        let last = try factory.create(.uaq).fromGregorian(CivilDate(year: 2077, month: 11, day: 16))
        assertYMD(last, 1500, 12, 30)
        XCTAssertThrowsError(try factory.create(.uaq).fromGregorian(CivilDate(year: 2077, month: 11, day: 17)))
        XCTAssertThrowsError(try factory.create(.diyanet).fromGregorian(CivilDate(year: 2028, month: 1, day: 27)))
        let diyanetFirst = try factory.create(.diyanet).fromGregorian(CivilDate(year: 1900, month: 5, day: 1))
        assertYMD(diyanetFirst, 1318, 1, 1)
    }

    func testJulianDayMath() {
        XCTAssertEqual(JulianDayMath.gregorianToJd(2025, 2, 14), 2460721)
        XCTAssertEqual(JulianDayMath.gregorianToJd(2000, 1, 1), 2451545)
        XCTAssertEqual(JulianDayMath.jdToGregorian(2451545), CivilDate(year: 2000, month: 1, day: 1))
        XCTAssertEqual(JulianDayMath.intPart(-0.00000005), 0)
        XCTAssertEqual(JulianDayMath.intPart(2.9999999), 3)
        XCTAssertEqual(JulianDayMath.intPart(-2.9999999), -3)
    }
}
