import XCTest
@testable import IslamicKitPlus

/// `timings_matrix.json` (14 places × 8 dates × 34 methods → raw hours) and
/// `timings_detail.json` (hand-picked cases with every derived output).
final class ConformanceTimingsTests: XCTestCase {
    private struct MatrixFile: Decodable {
        let cases: [MatrixCase]
    }

    private struct MatrixCase: Decodable {
        let id: String
        let date: String
        let lat: Double
        let lng: Double
        let params: FixtureParams
        let raw: FixtureRaw
    }

    private struct DetailFile: Decodable {
        let cases: [DetailCase]
    }

    private struct DetailCase: Decodable {
        struct Solar: Decodable {
            let transit: Double?
            let sunrise: Double?
            let sunset: Double?
            let asrStandard: Double?
            let asrHanafi: Double?
        }

        struct DateBlock: Decodable {
            let readable: String
            let timestamp: Int
            let gregorianWeekdayEn: String
            let gregorianMonthEn: String
            let gregorian: String
            let hijri: String
            let day: Int
            let month: Int
            let year: Int
            let monthLength: Int
            let weekdayEn: String
            let weekdayAr: String
            let monthEn: String
            let monthAr: String
            let method: String
            let holidays: [String]

            var asHijri: FixtureHijri {
                FixtureHijri(
                    hijri: hijri, day: day, month: month, year: year, monthLength: monthLength,
                    weekdayEn: weekdayEn, weekdayAr: weekdayAr, monthEn: monthEn, monthAr: monthAr,
                    holidays: holidays
                )
            }
        }

        struct Meta: Decodable {
            let timezone: String
            let methodId: Int
            let school: String
            let midnightMode: String
            let latitudeAdjustmentMethod: String
            let shafaq: String
            let offsets: [String: Int]
        }

        let id: String
        let lat: Double
        let lng: Double
        let params: FixtureParams
        let raw: FixtureRaw
        let solar: Solar
        let formatted: [String: [String: String]]
        let epochMillis: [String: Int?]
        /// The generator overwrites the input `date` string with this block;
        /// the input date is recovered from `gregorian` (`dd-mm-yyyy`).
        let date: DateBlock
        let meta: Meta
        let aladhanJson: String
        let aladhanJsonIso: String
        let aladhanJson12h: String
    }

    private let service = PrayerTimesService()

    func testMatrixRawHoursMatchExactly() throws {
        let file: MatrixFile = try ConformanceFixtures.load("timings_matrix")
        XCTAssertEqual(file.cases.count, 3808)
        for c in file.cases {
            let result = try service.timings(
                ConformanceFixtures.date(c.date), Coordinates(c.lat, c.lng), c.params.toCalculationParameters()
            )
            assertRawEqual(result.timings.raw, c.raw, c.id)
        }
    }

    func testDetailCasesMatchEveryDerivedOutput() throws {
        let file: DetailFile = try ConformanceFixtures.load("timings_detail")
        XCTAssertEqual(file.cases.count, 58)
        for c in file.cases {
            try checkDetail(c)
        }
    }

    private func checkDetail(_ c: DetailCase) throws {
        let id = c.id
        let params = c.params.toCalculationParameters()
        let coordinates = Coordinates(c.lat, c.lng)
        // The input date is the Gregorian date of the block (`dd-mm-yyyy`).
        let g = ConformanceFixtures.dmy(c.date.gregorian)
        let date = CivilDate(year: g.year, month: g.month, day: g.day)

        let result = try service.timings(date, coordinates, params)
        assertRawEqual(result.timings.raw, c.raw, id)

        // Unquantised solar events.
        let solar = SolarTime(date: date, coordinates: coordinates, elevation: params.elevation)
        assertClose(finite(solar.transit), c.solar.transit, accuracy: 1e-9, "\(id) solar.transit")
        assertClose(finite(solar.sunrise), c.solar.sunrise, accuracy: 1e-9, "\(id) solar.sunrise")
        assertClose(finite(solar.sunset), c.solar.sunset, accuracy: 1e-9, "\(id) solar.sunset")
        assertClose(finite(solar.afternoon(1)), c.solar.asrStandard, accuracy: 1e-9, "\(id) solar.asrStandard")
        assertClose(finite(solar.afternoon(2)), c.solar.asrHanafi, accuracy: 1e-9, "\(id) solar.asrHanafi")

        // Every format for every prayer.
        for format in TimeFormat.allCases {
            let expected = try XCTUnwrap(c.formatted[format.code], "\(id): fixture lacks format \(format.code)")
            for prayer in Prayer.allCases {
                assertSame(result.formatted(prayer, format), expected[prayer.key], "\(id) formatted[\(format.code)][\(prayer.key)]")
            }
        }

        // Absolute instants.
        for prayer in Prayer.allCases {
            let expected = try XCTUnwrap(c.epochMillis[prayer.key], "\(id): fixture lacks epochMillis \(prayer.key)")
            assertSame(result.time(prayer).epochMilliseconds, expected, "\(id) epochMillis[\(prayer.key)]")
        }

        // Date block.
        let d = result.date
        assertSame(d.readable, c.date.readable, "\(id) date.readable")
        assertSame(d.timestamp, c.date.timestamp, "\(id) date.timestamp")
        assertSame(d.gregorian.weekdayEn, c.date.gregorianWeekdayEn, "\(id) date.gregorianWeekdayEn")
        assertSame(d.gregorian.monthEn, c.date.gregorianMonthEn, "\(id) date.gregorianMonthEn")
        assertSame(d.gregorian.formatted, c.date.gregorian, "\(id) date.gregorian")
        assertSame(d.hijri.method.code, c.date.method, "\(id) date.method")
        assertHijri(d.hijri, c.date.asHijri, "\(id) date")

        // Meta.
        let m = result.meta
        assertSame(m.timezone, c.meta.timezone, "\(id) meta.timezone")
        assertSame(m.method.id, c.meta.methodId, "\(id) meta.methodId")
        assertSame(m.school.metaValue, c.meta.school, "\(id) meta.school")
        assertSame(m.midnightMode.metaValue, c.meta.midnightMode, "\(id) meta.midnightMode")
        assertSame(m.latitudeAdjustmentMethod.metaValue, c.meta.latitudeAdjustmentMethod, "\(id) meta.latitudeAdjustmentMethod")
        assertSame(m.shafaq.code, c.meta.shafaq, "\(id) meta.shafaq")
        var offsets = [String: Int]()
        for (prayer, minutes) in m.offsets { offsets[prayer.key] = minutes }
        assertSame(offsets, c.meta.offsets, "\(id) meta.offsets")

        // Full aladhan envelopes, byte for byte.
        assertSame(result.toAladhanJson().serialized(), c.aladhanJson, "\(id) aladhanJson")
        assertSame(result.toAladhanJson(format: .iso8601).serialized(), c.aladhanJsonIso, "\(id) aladhanJsonIso")
        assertSame(result.toAladhanJson(format: .h12).serialized(), c.aladhanJson12h, "\(id) aladhanJson12h")
    }

    /// The generator's `_finite`: NaN/infinite → `null`.
    private func finite(_ v: Double) -> Double? {
        v.isFinite ? v : nil
    }
}
