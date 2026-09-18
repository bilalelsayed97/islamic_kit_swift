import XCTest
import IslamicKitPlus

final class AladhanSerializationTests: XCTestCase {
    private let service = PrayerTimesService()
    private let london = Coordinates(51.508515, -0.1254872)
    private let params = CalculationParameters(method: .isna, utcOffset: UTCOffset(hours: 1), timezoneName: "Europe/London")
    private let april24 = CivilDate(year: 2014, month: 4, day: 24)

    func testSingleDateEnvelopeMatchesAladhanShape() throws {
        let json = try service.timings(april24, london, params).toAladhanJson()

        XCTAssertEqual(json["code"], 200)
        XCTAssertEqual(json["status"], "OK")
        XCTAssertEqual(json.keys, ["code", "status", "data"])

        let data = try XCTUnwrap(json["data"]?.object)
        XCTAssertEqual(data.keys, ["timings", "date", "meta"])
        let timings = try XCTUnwrap(data["timings"]?.object)
        XCTAssertEqual(timings["Fajr"], "03:57")
        XCTAssertEqual(timings["Dhuhr"], "13:00")
        XCTAssertNotNil(timings["Firstthird"])
        XCTAssertEqual(timings.keys, Prayer.allCases.map(\.key))

        let date = try XCTUnwrap(data["date"]?.object)
        XCTAssertEqual(date.keys, ["readable", "timestamp", "hijri", "gregorian"])
        let gregorian = try XCTUnwrap(date["gregorian"]?.object)
        XCTAssertEqual(gregorian["date"], "24-04-2014")
        XCTAssertEqual(gregorian["month"]?["number"], 4)
        XCTAssertEqual(gregorian["day"], "24")
        XCTAssertEqual(gregorian["lunarSighting"], false)
        XCTAssertEqual(date["timestamp"], .string("1398294000"))

        let hijri = try XCTUnwrap(date["hijri"]?.object)
        XCTAssertNotNil(hijri["weekday"]?["ar"])
        XCTAssertEqual(hijri["month"]?["days"], 29)
        XCTAssertEqual(hijri["day"], "24")
        XCTAssertEqual(hijri["method"], "HJCoSA")
        XCTAssertEqual(hijri["adjustedHolidays"], [])

        let meta = try XCTUnwrap(data["meta"]?.object)
        XCTAssertEqual(meta.keys, ["latitude", "longitude", "timezone", "method", "latitudeAdjustmentMethod",
                                   "midnightMode", "school", "offset"])
        XCTAssertEqual(meta["method"]?["id"], 2)
        XCTAssertEqual(meta["method"]?["params"]?.object?.keys, ["Fajr", "Isha"])
        XCTAssertEqual(meta["method"]?["params"]?["Fajr"], 15)
        XCTAssertEqual(meta["method"]?["location"]?["latitude"], .double(39.70421229999999))
        XCTAssertEqual(meta["school"], "STANDARD")
        XCTAssertEqual(meta["latitudeAdjustmentMethod"], "MIDDLE_OF_THE_NIGHT")
        XCTAssertEqual(meta["midnightMode"], "JAFARI")
        XCTAssertEqual(meta["offset"]?.object?.count, 9)
        XCTAssertEqual(meta["offset"]?.object?.keys,
                       ["Imsak", "Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha", "Midnight"])
    }

    func testSerializedStringShape() throws {
        let json = try service.timings(april24, london, params).toAladhanJson().serialized()
        XCTAssertTrue(json.hasPrefix("{\"code\":200,\"status\":\"OK\",\"data\":{\"timings\":{\"Imsak\":\"03:47\",\"Fajr\":\"03:57\""))
        XCTAssertTrue(json.contains("\"latitude\":51.508515,\"longitude\":-0.1254872,\"timezone\":\"Europe/London\""))
        XCTAssertTrue(json.contains("\"params\":{\"Fajr\":15,\"Isha\":15},\"location\":{\"latitude\":39.70421229999999,\"longitude\":-86.39943869999999}"))
        XCTAssertTrue(json.contains("\"weekday\":{\"en\":\"Thursday\",\"ar\":\"الخميس\"}"))
        XCTAssertTrue(json.hasSuffix("\"Isha\":0,\"Midnight\":0}}}}"))
    }

    func testCalendarTimingsCarryTheTimezoneSuffix() throws {
        let month = try service.monthlyCalendar(2014, 4, london, params)
        let json = calendarAladhanJson(month)
        let data = try XCTUnwrap(json["data"]?.array)
        XCTAssertEqual(data.count, 30)
        XCTAssertTrue(data.first?["timings"]?["Fajr"]?.string?.hasSuffix("(Europe/London)") == true)
        XCTAssertEqual(data[23]["timings"]?["Fajr"], "03:57 (Europe/London)")
        // ISO and float formats never carry the suffix.
        XCTAssertEqual(calendarAladhanJson(month, format: .iso8601)["data"]?[23]?["timings"]?["Fajr"],
                       "2014-04-24T03:57:00+01:00")
        XCTAssertEqual(calendarAladhanJson(month, format: .float)["data"]?[23]?["timings"]?["Fajr"], "3.95")
    }

    func testAnnualCalendarIsKeyedByMonthString() throws {
        let year = try service.annualCalendar(2014, london, params)
        let json = annualCalendarAladhanJson(year)
        let data = try XCTUnwrap(json["data"]?.object)
        XCTAssertEqual(data.keys, (1...12).map(String.init))
        XCTAssertEqual(data["2"]?.array?.count, 28)
    }

    func testMethodsResponseExposesMWLWithParams() {
        let json = methodsAladhanJson()
        let data = json["data"]!.object!
        let mwl = data["MWL"]!
        XCTAssertEqual(mwl["id"], 3)
        XCTAssertEqual(mwl["params"]?["Fajr"], 18)
        XCTAssertEqual(mwl["params"]?["Isha"], 17)
        XCTAssertEqual(data.keys.first, "KARACHI")
        XCTAssertEqual(data.keys.last, "CUSTOM")
        XCTAssertEqual(data.count, 34)
        XCTAssertEqual(data["CUSTOM"]?.object?.keys, ["id", "name"])
        XCTAssertEqual(data["MOONSIGHTING"]?["params"], ["shafaq": "general"])
        XCTAssertEqual(data["TEHRAN"]?["params"]?.object?.keys, ["Fajr", "Isha", "Maghrib", "Midnight"])
        XCTAssertEqual(data["TEHRAN"]?["params"]?["Fajr"], .double(17.7))
        XCTAssertEqual(data["TEHRAN"]?["params"]?["Maghrib"], .double(4.5))
        XCTAssertEqual(data["TEHRAN"]?["params"]?["Midnight"], "JAFARI")
        XCTAssertEqual(data["MAKKAH"]?["params"]?["Fajr"], .double(18.5))
    }

    func testMakkahSerializesIshaAs90Min() {
        let json = methodsAladhanJson()
        XCTAssertEqual(json["data"]?["MAKKAH"]?["params"]?["Isha"], "90 min")
    }

    func testNextPrayerAndQiblaEnvelopes() throws {
        let day = try service.timings(april24, london, params)
        let next = nextPrayerAladhanJson(day, .asr)
        XCTAssertEqual(next["data"]?["timings"], ["Asr": "16:56"])
        XCTAssertEqual(next["data"]?.object?.keys, ["timings", "date", "meta"])

        let qibla = qiblaAladhanJson(service.qibla(Coordinates(51.5073509, -0.1277583)))
        XCTAssertEqual(qibla["data"]?["latitude"], .double(51.5073509))
        XCTAssertEqual(qibla["data"]?["direction"]?.double ?? 0, 118.98724271029, accuracy: 1e-6)
        XCTAssertEqual(qibla["data"]?.object?.keys, ["latitude", "longitude", "direction"])
    }

    func testMoonsightingMetaEchoesNone() throws {
        let r = try service.timings(april24, london, CalculationParameters(method: .moonsighting, utcOffset: UTCOffset(hours: 1), shafaq: .abyad))
        let meta = r.toAladhanData()["meta"]!
        XCTAssertEqual(meta["latitudeAdjustmentMethod"], "NONE")
        XCTAssertEqual(meta["method"]?["params"], ["shafaq": "abyad"])
    }
}
