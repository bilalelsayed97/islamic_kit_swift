import XCTest
@testable import IslamicKitPlus

/// `hijri.json`: full `fromGregorian` entries (with range errors and
/// adjustments), `toGregorian` entries and the compact daily sweep.
final class ConformanceHijriTests: XCTestCase {
    private struct File: Decodable {
        let fromGregorian: [FromEntry]
        let toGregorian: [ToEntry]
        let daily: Daily
    }

    private struct FromEntry: Decodable {
        let method: String
        let date: String
        let adjustment: Int?
        let error: String?
        let hijri: String?
        let day: Int?
        let month: Int?
        let year: Int?
        let monthLength: Int?
        let weekdayEn: String?
        let weekdayAr: String?
        let monthEn: String?
        let monthAr: String?
        let holidays: [String]?

        var expected: FixtureHijri {
            FixtureHijri(
                hijri: hijri!, day: day!, month: month!, year: year!, monthLength: monthLength!,
                weekdayEn: weekdayEn!, weekdayAr: weekdayAr!, monthEn: monthEn!, monthAr: monthAr!,
                holidays: holidays!
            )
        }
    }

    private struct ToEntry: Decodable {
        let method: String
        let hijri: String
        let adjustment: Int?
        let error: String?
        let date: String?
    }

    private struct Daily: Decodable {
        let columns: [String]
        let rows: [DailyRow]
    }

    /// `[method, date, hijri, monthLength]`.
    private struct DailyRow: Decodable {
        let method: String
        let date: String
        let hijri: String
        let monthLength: Int

        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            method = try c.decode(String.self)
            date = try c.decode(String.self)
            hijri = try c.decode(String.self)
            monthLength = try c.decode(Int.self)
        }
    }

    private let factory = HijriConverterFactory()

    private func converter(_ code: String) -> any HijriConverter {
        factory.create(CalendarMethod.allCases.first { $0.code == code }!)
    }

    func testFromGregorianEntries() throws {
        let file: File = try ConformanceFixtures.load("hijri")
        XCTAssertEqual(file.fromGregorian.count, 8157)
        for e in file.fromGregorian {
            let id = "\(e.method) fromGregorian(\(e.date), adj \(e.adjustment ?? 0))"
            let date = ConformanceFixtures.date(e.date)
            do {
                let h = try converter(e.method).fromGregorian(date, adjustment: e.adjustment ?? 0)
                if e.error != nil {
                    XCTFail("\(id): expected \(e.error!) got \(h.formatted)")
                    continue
                }
                assertSame(h.method.code, e.method, "\(id) method")
                assertHijri(h, e.expected, id)
            } catch IslamicKitError.gregorianDateOutOfRange {
                if e.error == nil { XCTFail("\(id): unexpected gregorianDateOutOfRange") }
            }
        }
    }

    func testToGregorianEntries() throws {
        let file: File = try ConformanceFixtures.load("hijri")
        XCTAssertEqual(file.toGregorian.count, 11888)
        for e in file.toGregorian {
            let id = "\(e.method) toGregorian(\(e.hijri), adj \(e.adjustment ?? 0))"
            let h = ConformanceFixtures.dmy(e.hijri)
            do {
                let g = try converter(e.method).toGregorian(
                    year: h.year, month: h.month, day: h.day, adjustment: e.adjustment ?? 0
                )
                if e.error != nil {
                    XCTFail("\(id): expected \(e.error!) got \(g)")
                    continue
                }
                assertSame(g.isoString, e.date, id)
            } catch IslamicKitError.hijriDateOutOfRange {
                if e.error == nil { XCTFail("\(id): unexpected hijriDateOutOfRange") }
            }
        }
    }

    func testDailySweep() throws {
        let file: File = try ConformanceFixtures.load("hijri")
        XCTAssertEqual(file.daily.columns, ["method", "date", "hijri", "monthLength"])
        XCTAssertEqual(file.daily.rows.count, 29610)
        var converters = [String: any HijriConverter]()
        for row in file.daily.rows {
            let conv = converters[row.method] ?? {
                let c = converter(row.method)
                converters[row.method] = c
                return c
            }()
            let h = try conv.fromGregorian(ConformanceFixtures.date(row.date))
            assertSame(h.formatted, row.hijri, "\(row.method) \(row.date) hijri")
            assertSame(h.monthLength, row.monthLength, "\(row.method) \(row.date) monthLength")
        }
    }
}
