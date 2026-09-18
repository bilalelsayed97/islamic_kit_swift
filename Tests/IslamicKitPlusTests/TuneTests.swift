import XCTest
import IslamicKitPlus

final class TuneTests: XCTestCase {
    private let london = Coordinates(51.508515, -0.1254872)
    private let service = PrayerTimesService()
    private let april24 = CivilDate(year: 2014, month: 4, day: 24)

    func testPerPrayerTuneShiftsTheComputedTime() throws {
        let base = CalculationParameters(method: .isna, utcOffset: UTCOffset(hours: 1))
        let untuned = try service.timings(april24, london, base)
        XCTAssertEqual(untuned.formatted(.fajr), "03:57")

        let tuned = try service.timings(april24, london, base.with { $0.tune = Tune(fajr: 5) }) // +5 minutes
        XCTAssertEqual(tuned.formatted(.fajr), "04:02")

        // Negative tune, and the night thirds are never tuned.
        let negative = try service.timings(april24, london, base.with { $0.tune = Tune(isha: -3, midnight: 7) })
        XCTAssertEqual(negative.formatted(.isha), "21:59")
        XCTAssertEqual(negative.formatted(.midnight), "00:12")
        XCTAssertEqual(negative.formatted(.firstThird), untuned.formatted(.firstThird))
    }

    func testTuneRoundTripsTheAladhanCsvOrder() {
        let tune = Tune(csv: "5,3,5,7,9,-1,0,8,-6")
        XCTAssertEqual(tune.imsak, 5)
        XCTAssertEqual(tune.fajr, 3)
        XCTAssertEqual(tune.maghrib, -1) // Maghrib precedes Sunset in the aladhan order
        XCTAssertEqual(tune.sunset, 0)
        XCTAssertEqual(tune.midnight, -6)
        XCTAssertEqual(tune.csv, "5,3,5,7,9,-1,0,8,-6")
    }

    func testCsvParsingFallbacks() {
        XCTAssertEqual(Tune(csv: "1, 2"), Tune(imsak: 1, fajr: 2))
        XCTAssertEqual(Tune(csv: "x,,3"), Tune(sunrise: 3))
        XCTAssertEqual(Tune(csv: ""), .none)
        XCTAssertTrue(Tune(csv: "0,0").isEmpty)
        XCTAssertFalse(Tune(isha: 1).isEmpty)
        XCTAssertEqual(Tune(fajr: 3).toMap()[.fajr], 3)
        XCTAssertEqual(Tune.none.toMap().count, 9)
        XCTAssertNil(Tune.none.toMap()[.firstThird])
    }

    func testOffsetsAppearInTheAladhanMetaBlock() throws {
        let json = try service.timings(
            april24, london,
            CalculationParameters(method: .isna, utcOffset: UTCOffset(hours: 1), tune: Tune(fajr: 3, isha: 8))
        ).toAladhanJson()
        let offset = json["data"]?["meta"]?["offset"]
        XCTAssertEqual(offset?["Fajr"], 3)
        XCTAssertEqual(offset?["Isha"], 8)
        XCTAssertEqual(offset?["Dhuhr"], 0)
    }
}
