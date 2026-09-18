import XCTest
@testable import IslamicKitPlus

/// The two directions of a converter must be inverses: a Hijri calendar screen
/// places a month with `toGregorian` and labels its days with `fromGregorian`,
/// so any disagreement shows up as a month that starts on "day 2".
final class HijriRoundTripTests: XCTestCase {
    private let factory = HijriConverterFactory()

    private func assertRoundTrips(
        _ method: CalendarMethod,
        from: CivilDate,
        to: CivilDate,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let converter = factory.create(method)
        var date = from
        while date <= to {
            let hijri = try converter.fromGregorian(date)
            let back = try converter.toGregorian(year: hijri.year, month: hijri.month, day: hijri.day)
            guard back == date else {
                return XCTFail(
                    "\(method.code): \(date) is \(hijri.formatted), which converts back to \(back)",
                    file: file, line: line
                )
            }
            date = date.addingDays(1)
        }
    }

    private func civil(_ ymd: YMD) -> CivilDate {
        CivilDate(year: ymd.year, month: ymd.month, day: ymd.day)
    }

    func testUmmAlQuraRoundTripsEveryDayOfItsTable() throws {
        let table = TableHijriConverter.ummAlQura
        try assertRoundTrips(.uaq, from: civil(table.gregorianFrom), to: civil(table.gregorianTo))
    }

    func testDiyanetRoundTripsEveryDayOfItsTable() throws {
        let table = TableHijriConverter.diyanet
        try assertRoundTrips(.diyanet, from: civil(table.gregorianFrom), to: civil(table.gregorianTo))
    }

    func testMathematicalRoundTrips() throws {
        try assertRoundTrips(
            .mathematical,
            from: CivilDate(year: 1990, month: 1, day: 1),
            to: CivilDate(year: 2040, month: 12, day: 31)
        )
    }

    /// Before its last announcement, an announcement moves single days of a
    /// month, which the surrounding days (still read off the table) cannot
    /// mirror.
    func testHjcosaRoundTripsEveryDayAfterItsLastAnnouncement() throws {
        try assertRoundTrips(
            .hjcosa,
            from: CivilDate(year: 2021, month: 9, day: 9),
            to: civil(TableHijriConverter.ummAlQura.gregorianTo)
        )
    }

    func testHjcosaRoundTripsEveryAnnouncedDate() throws {
        let converter = factory.create(.hjcosa)
        for gregorian in HijriSightings.gregorianToHijri.keys {
            let parts = gregorian.split(separator: "-").map { Int($0)! }
            let date = CivilDate(year: parts[2], month: parts[1], day: parts[0])
            let hijri = try converter.fromGregorian(date)
            XCTAssertEqual(
                try converter.toGregorian(year: hijri.year, month: hijri.month, day: hijri.day),
                date,
                gregorian
            )
        }
    }

    /// The arithmetic calendar put these on the 24th, the 17th and the 17th.
    func testTheMonthsThatUsedToStartADayOff() throws {
        let hjcosa = factory.create(.hjcosa)
        XCTAssertEqual(try hjcosa.toGregorian(year: 1447, month: 4, day: 1), CivilDate(year: 2025, month: 9, day: 23))
        XCTAssertEqual(try hjcosa.toGregorian(year: 1448, month: 1, day: 1), CivilDate(year: 2026, month: 6, day: 16))
        XCTAssertEqual(try hjcosa.toGregorian(year: 1448, month: 2, day: 1), CivilDate(year: 2026, month: 7, day: 15))
    }

    /// Sha'ban 1446 has 29 days.
    func testADayPastTheMonthsEndRunsIntoTheNextMonth() throws {
        let uaq = factory.create(.uaq)
        XCTAssertEqual(
            try uaq.toGregorian(year: 1446, month: 8, day: 30),
            try uaq.toGregorian(year: 1446, month: 9, day: 1)
        )
    }

    func testAnAdjustmentShiftsTheGregorianResultByWholeDays() throws {
        let uaq = factory.create(.uaq)
        XCTAssertEqual(
            try uaq.toGregorian(year: 1446, month: 8, day: 15, adjustment: 1),
            CivilDate(year: 2025, month: 2, day: 15)
        )
        XCTAssertEqual(
            try uaq.toGregorian(year: 1446, month: 8, day: 15, adjustment: -1),
            CivilDate(year: 2025, month: 2, day: 13)
        )
    }
}
