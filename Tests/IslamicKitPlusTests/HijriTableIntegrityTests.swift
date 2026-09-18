import XCTest
@testable import IslamicKitPlus

final class HijriTableIntegrityTests: XCTestCase {
    private func assertTable(
        _ data: [Int], count: Int, first: Int, last: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(data.count, count, "count", file: file, line: line)
        XCTAssertEqual(data.first, first, "first", file: file, line: line)
        XCTAssertEqual(data.last, last, "last", file: file, line: line)
        for i in 1..<data.count {
            let delta = data[i] - data[i - 1]
            XCTAssertTrue((28...30).contains(delta), "delta at \(i) is \(delta)", file: file, line: line)
        }
    }

    func testUmmAlQura() {
        assertTable(UmmAlQuraTable.data, count: 1741, first: 28607, last: 79990)
        XCTAssertEqual(UmmAlQuraTable.data.indices.filter { $0 > 0 && UmmAlQuraTable.data[$0] - UmmAlQuraTable.data[$0 - 1] == 28 }.count, 1)
    }

    func testDiyanet() {
        assertTable(DiyanetTable.data, count: 2197, first: 15141, last: 79990)
    }

    func testSightingsAndHolidays() {
        XCTAssertEqual(HijriSightings.gregorianToHijri.count, 22)
        XCTAssertEqual(HijriSightings.hijriToGregorian.count, 22)
        XCTAssertEqual(HijriSightings.hijriToGregorian["01-09-1439"], "17-05-2018")
        XCTAssertEqual(HijriHolidays.byMonth[9]?[1]?.first, "1st Day of Ramadan")
        XCTAssertEqual(HijriHolidays.byMonth.count, 12)
        XCTAssertEqual(Localizer.islamicMonths.count, 12)
        XCTAssertEqual(Localizer.gregorianWeekdays.count, 7)
        XCTAssertEqual(Localizer.hijriWeekday(5).en, "Friday")
        XCTAssertEqual(Localizer.monthAbbrEn.count, 12)
    }
}
