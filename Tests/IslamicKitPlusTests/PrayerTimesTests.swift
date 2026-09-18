import XCTest
import IslamicKitPlus

final class PrayerTimesTests: XCTestCase {
    private let service = PrayerTimesService()

    private func assertTimes(
        _ result: PrayerResult, _ expected: [Prayer: String], format: TimeFormat = .h24,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        for (prayer, time) in expected {
            XCTAssertEqual(result.formatted(prayer, format), time, "\(prayer.key) == \(time)", file: file, line: line)
        }
    }

    // MARK: Adhan reference — Raleigh NC 2015-07-12, ISNA

    private let raleigh = Coordinates(35.7750, -78.6336)
    private let raleighParams = CalculationParameters(
        method: .isna,
        school: .hanafi,
        utcOffset: UTCOffset(hours: -4) // America/New_York, EDT
    )

    func testAdhanReferenceVector() throws {
        // Reference vector published with the Adhan library. If the solar
        // algorithm is ported correctly, every one of these matches to the minute.
        let result = try service.timings(CivilDate(year: 2015, month: 7, day: 12), raleigh, raleighParams)
        assertTimes(result, [
            .fajr: "4:42 am",
            .sunrise: "6:08 am",
            .dhuhr: "1:21 pm",
            .asr: "6:22 pm",
            .maghrib: "8:32 pm",
            .isha: "9:57 pm",
        ], format: .h12)
    }

    func testShafiAsrDiffersFromHanafi() throws {
        let shafi = try service.timings(
            CivilDate(year: 2015, month: 7, day: 12), raleigh,
            raleighParams.with { $0.school = .standard }
        )
        XCTAssertEqual(shafi.formatted(.asr, .h12), "5:09 pm")
    }

    // MARK: ISNA London 2014-04-24 (24h)

    private let london = Coordinates(51.508515, -0.1254872)
    private let londonParams = CalculationParameters(
        method: .isna,
        utcOffset: UTCOffset(hours: 1) // Europe/London, BST on 2014-04-24
    )
    private let april24 = CivilDate(year: 2014, month: 4, day: 24)

    func testISNALondon24h() throws {
        let result = try service.timings(april24, london, londonParams)
        assertTimes(result, [
            .fajr: "03:57",
            .sunrise: "05:46",
            // ISNA publishes Dhuhr a minute past the zenith.
            .dhuhr: "13:00",
            .asr: "16:56",
            .sunset: "20:12",
            .maghrib: "20:12",
            .isha: "22:02",
            .imsak: "03:47",
            // Night measured sunset -> next Fajr (the engine's default basis).
            .midnight: "00:05",
            .firstThird: "22:47",
            .lastThird: "01:22",
        ])
    }

    func testRawHoursAndOtherFormats() throws {
        let result = try service.timings(april24, london, londonParams)
        XCTAssertEqual(result.time(.fajr).hours, 3.95)
        XCTAssertEqual(result.formatted(.fajr, .float), "3.95")
        XCTAssertEqual(result.formatted(.fajr, .h12NoSuffix), "3:57")
        XCTAssertEqual(result.formatted(.dhuhr, .h12), "1:00 pm")
        XCTAssertEqual(result.formatted(.dhuhr, .float), "13.0")
        XCTAssertEqual(result.time(.lastThird).hours.map { $0 > 24 }, true)
        XCTAssertEqual(result.time(.fajr).epochMilliseconds, (1398297600 + Int(3.95 * 3600) - 3600) * 1000)
        XCTAssertEqual(result.time(.fajr).description, "Fajr: 03:57")
        XCTAssertEqual(result.timings.toFormattedMap()[.isha], "22:02")
        XCTAssertEqual(result.timings.raw.entries.map(\.prayer), Prayer.allCases)
    }

    // MARK: Midnight basis

    func testStandardModeMeasuresSunsetToSunrise() throws {
        let r = try service.timings(april24, london, londonParams.with { $0.midnightMode = .standard })
        XCTAssertEqual(r.formatted(.midnight), "00:59")
    }

    func testDefaultJafariMeasuresSunsetToFajr() throws {
        let r = try service.timings(april24, london, londonParams)
        XCTAssertEqual(r.formatted(.midnight), "00:05")
        XCTAssertEqual(r.meta.midnightMode, .jafari)
    }

    // MARK: ISO-8601 with day rollover

    func testISOMidLatitudeFajr() throws {
        let r = try service.timings(april24, london, londonParams)
        XCTAssertEqual(r.formatted(.fajr, .iso8601), "2014-04-24T03:57:00+01:00")
    }

    func testISOHighLatitudeIshaRollsToNextDay() throws {
        let r = try service.timings(april24, Coordinates(70, -10), londonParams)
        XCTAssertEqual(r.formatted(.isha, .iso8601), "2014-04-25T01:40:00+01:00")
    }

    func testISOHighLatitudeFajrRollsToPreviousDay() throws {
        let r = try service.timings(april24, Coordinates(70, 40), londonParams)
        XCTAssertEqual(r.formatted(.fajr, .iso8601), "2014-04-23T22:20:00+01:00")
    }

    func testISONegativeOffsetSuffix() throws {
        let r = try service.timings(CivilDate(year: 2015, month: 7, day: 12), raleigh, raleighParams)
        XCTAssertEqual(r.formatted(.fajr, .iso8601), "2015-07-12T04:42:00-04:00")
    }

    // MARK: High latitude

    func testSafeBoundsKeepEveryTimeValidWhereTheSunStillRises() throws {
        let r = try service.timings(
            CivilDate(year: 2018, month: 1, day: 19),
            Coordinates(67.104732, 67.104732),
            CalculationParameters(method: .karachi, utcOffset: UTCOffset(hours: 5)) // Asia/Yekaterinburg
        )
        for prayer in Prayer.allCases {
            XCTAssertNotEqual(r.formatted(prayer), invalidTime, prayer.key)
        }
    }

    func testPolarNightInvalidatesTheWholeDay() throws {
        let r = try service.timings(
            CivilDate(year: 2024, month: 12, day: 15),
            Coordinates(78.2232, 15.6469), // Longyearbyen
            CalculationParameters(utcOffset: UTCOffset(hours: 1))
        )
        for prayer in Prayer.allCases {
            XCTAssertEqual(r.formatted(prayer), invalidTime, prayer.key)
            XCTAssertNil(r.time(prayer).hours, prayer.key)
        }
        XCTAssertEqual(r.timings.raw, .allInvalid)
    }

    func testRuleNoneLeavesAnUnreachableAngleInvalid() throws {
        // Stockholm at the solstice: the sun sets, but never falls 18° below
        // the horizon, so Fajr and Isha have no angle-based solution.
        let stockholm = Coordinates(59.3293, 18.0686)
        let params = CalculationParameters(utcOffset: UTCOffset(hours: 2))
        let solstice = CivilDate(year: 2024, month: 6, day: 21)

        let none = try service.timings(solstice, stockholm, params.with { $0.highLatitudeRule = .none })
        XCTAssertEqual(none.formatted(.sunrise), "03:31")
        XCTAssertEqual(none.formatted(.fajr), invalidTime)
        XCTAssertEqual(none.formatted(.isha), invalidTime)
        XCTAssertEqual(none.formatted(.imsak), invalidTime)
        XCTAssertEqual(none.formatted(.midnight), invalidTime) // jafari anchor is the (invalid) Fajr
        XCTAssertNotEqual(none.formatted(.sunset), invalidTime)

        // The default rule bounds both at the middle of the night instead.
        let bounded = try service.timings(solstice, stockholm, params)
        XCTAssertEqual(bounded.formatted(.fajr), "00:50")
        XCTAssertEqual(bounded.formatted(.isha), "00:50")
    }

    // MARK: Moonsighting London 2014-04-24

    func testMoonsightingLondon() throws {
        let result = try service.timings(
            april24, london,
            CalculationParameters(method: .moonsighting, utcOffset: UTCOffset(hours: 1))
        )
        XCTAssertEqual(result.formatted(.fajr), "04:04")
        XCTAssertEqual(result.formatted(.isha), "21:21")
        XCTAssertEqual(result.formatted(.imsak), "03:54")
        XCTAssertEqual(result.formatted(.sunrise), "05:46")
        // Method adjustments move Dhuhr +5 and Maghrib +3.
        XCTAssertEqual(result.formatted(.dhuhr), "13:04")
        XCTAssertEqual(result.formatted(.maghrib), "20:15")
    }

    func testMoonsightingWithoutStrategyThrows() {
        let calculator = AstronomicalCalculator()
        XCTAssertThrowsError(
            try calculator.compute(april24, london, CalculationParameters(method: .moonsighting))
        ) { error in
            XCTAssertEqual(error as? IslamicKitError, .twilightStrategyRequired(method: "MOONSIGHTING"))
        }
        // Not consulted when the rule is `none`, so no throw.
        XCTAssertNoThrow(
            try calculator.compute(april24, london,
                                   CalculationParameters(method: .moonsighting, highLatitudeRule: .none))
        )
    }

    // MARK: Umm al-Qura Ramadan Isha interval

    private let makkah = Coordinates(21.4225, 39.8262)
    private let makkahParams = CalculationParameters(method: .makkah, utcOffset: UTCOffset(hours: 3))

    private func gapMinutes(_ r: PrayerResult) -> Int {
        let maghrib = r.timings.time(.maghrib).hours!
        let isha = r.timings.time(.isha).hours!
        return Int(((isha - maghrib) * 60).rounded())
    }

    func testInsideRamadanTheIntervalIs120Minutes() throws {
        // 1447 AH Ramadan runs from roughly 2026-02-18.
        let r = try service.timings(CivilDate(year: 2026, month: 2, day: 20), makkah, makkahParams)
        XCTAssertEqual(gapMinutes(r), 120)
    }

    func testOutsideRamadanTheIntervalIs90Minutes() throws {
        let r = try service.timings(CivilDate(year: 2026, month: 4, day: 20), makkah, makkahParams)
        XCTAssertEqual(gapMinutes(r), 90)
    }

    func testNoOtherMethodVariesByMonth() throws {
        let r = try service.timings(CivilDate(year: 2026, month: 2, day: 20), makkah,
                                    makkahParams.with { $0.method = .qatar })
        XCTAssertEqual(gapMinutes(r), 90)
    }

    func testRamadanCheckUsesUmmAlQuraRegardlessOfCalendarMethod() throws {
        let r = try service.timings(CivilDate(year: 2026, month: 2, day: 20), makkah,
                                    makkahParams.with { $0.calendarMethod = .mathematical })
        XCTAssertEqual(gapMinutes(r), 120)
        XCTAssertEqual(r.date.hijri.method, .mathematical)
    }

    func testOutOfTableRangeIsNotRamadanButDateBlockThrows() throws {
        // The mathematical calendar has no range, so timings succeed and the
        // Ramadan rule silently falls back to the ordinary interval.
        let r = try service.timings(CivilDate(year: 2100, month: 3, day: 1), makkah,
                                    makkahParams.with { $0.calendarMethod = .mathematical })
        XCTAssertEqual(gapMinutes(r), 90)
        // The default HJCoSA date block rejects the same date.
        XCTAssertThrowsError(try service.timings(CivilDate(year: 2100, month: 3, day: 1), makkah, makkahParams)) { error in
            guard case .gregorianDateOutOfRange? = error as? IslamicKitError else {
                return XCTFail("unexpected error \(error)")
            }
        }
    }

    // MARK: Next prayer

    func testAfterDhuhrReturnsAsr() throws {
        let next = try service.nextPrayer(CivilDateTime(year: 2014, month: 4, day: 24, hour: 13, minute: 30), london, londonParams)
        XCTAssertEqual(next.prayer, .asr)
        XCTAssertEqual(next.time.format(), "16:56")
        XCTAssertEqual(next.onDate, april24)
    }

    func testAfterIshaRollsToNextDayFajr() throws {
        let next = try service.nextPrayer(CivilDateTime(year: 2014, month: 4, day: 24, hour: 23, minute: 30), london, londonParams)
        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertEqual(next.onDate, CivilDate(year: 2014, month: 4, day: 25))
        XCTAssertEqual(next.time.date, CivilDate(year: 2014, month: 4, day: 25))
    }

    func testNextPrayerByAddress() throws {
        let next = try service.nextPrayerByAddress("London, UK", CivilDateTime(year: 2014, month: 4, day: 24, hour: 2),
                                                   CalculationParameters(method: .isna))
        XCTAssertEqual(next.prayer, .fajr)
        // The curated London offset (standard time, +00:00) is applied.
        XCTAssertEqual(next.time.utcOffset, .zero)
        XCTAssertEqual(next.time.format(), "02:57")
    }

    // MARK: Calendars

    func testMonthlyCalendarHasOneEntryPerDay() throws {
        let month = try service.monthlyCalendar(2014, 4, london, londonParams)
        XCTAssertEqual(month.count, 30)
        XCTAssertFalse(month.first!.formatted(.fajr).isEmpty)
        XCTAssertEqual(month.last!.date.gregorian.day, 30)
        XCTAssertEqual(try service.monthlyCalendar(2024, 2, london, londonParams).count, 29)
    }

    func testAnnualCalendarKeyedBy12Months() throws {
        let year = try service.annualCalendar(2014, london, londonParams)
        XCTAssertEqual(year.keys.sorted(), Array(1...12))
        XCTAssertEqual(year[1]!.count, 31)
    }

    func testRangeCalendarRejectsMoreThan11Months() {
        XCTAssertThrowsError(
            try service.rangeCalendar(CivilDate(year: 2014, month: 1, day: 1), CivilDate(year: 2015, month: 1, day: 1), london, londonParams)
        ) { error in
            XCTAssertEqual(error as? IslamicKitError, .invalidDateRange("Date range must be at most 11 months."))
        }
        XCTAssertThrowsError(
            try service.rangeCalendar(CivilDate(year: 2014, month: 1, day: 2), CivilDate(year: 2014, month: 1, day: 1), london, londonParams)
        ) { error in
            XCTAssertEqual(error as? IslamicKitError, .invalidDateRange("end must be on or after start."))
        }
    }

    func testRangeCalendarIsInclusive() throws {
        let days = try service.rangeCalendar(CivilDate(year: 2014, month: 1, day: 30), CivilDate(year: 2014, month: 2, day: 2), london, londonParams)
        XCTAssertEqual(days.map(\.date.gregorian.day), [30, 31, 1, 2])
        XCTAssertEqual(try service.rangeCalendar(CivilDate(year: 2014, month: 1, day: 31), CivilDate(year: 2014, month: 12, day: 31), london, londonParams).count, 335)
    }

    func testHijriCalendars() throws {
        // Ramadan 1435 (HJCoSA sighting override starts it on 2014-06-29).
        let ramadan = try service.monthlyHijriCalendar(1435, 9, london, londonParams)
        XCTAssertEqual(ramadan.first?.date.gregorian.formatted, "29-06-2014")
        XCTAssertEqual(ramadan.count, ramadan.first!.date.hijri.monthLength)
        let year = try service.annualHijriCalendar(1446, london, londonParams)
        XCTAssertEqual(year.keys.sorted(), Array(1...12))
        XCTAssertEqual(year[8]!.count, 29)
        let byCity = try service.monthlyHijriCalendarByCity(1446, 8, "London", country: "GB")
        XCTAssertEqual(byCity.count, 29)
        XCTAssertEqual(byCity.first?.meta.timezone, "UTC")
    }

    // MARK: By city / address

    func testTimingsByCityAppliesTheCityOffsetOnlyWhenUnset() throws {
        let auto = try service.timingsByCity("Cairo", date: april24, country: "EG", params: CalculationParameters(method: .egypt))
        XCTAssertEqual(auto.timings.utcOffset, UTCOffset(hours: 2))
        XCTAssertEqual(auto.meta.timezone, "UTC+02:00")
        let explicit = try service.timingsByCity("Cairo", date: april24, country: "EG",
                                                 params: CalculationParameters(method: .egypt, utcOffset: UTCOffset(hours: 3)))
        XCTAssertEqual(explicit.timings.utcOffset, UTCOffset(hours: 3))
        XCTAssertEqual(try service.timingsByAddress("Trafalgar Square, London, UK", date: april24).meta.coordinates.latitude,
                       51.5073509)
    }

    func testUnknownLocationThrows() {
        XCTAssertThrowsError(try service.timingsByCity("Atlantis", date: april24)) { error in
            XCTAssertEqual(error as? IslamicKitError, .locationNotFound(query: "Atlantis"))
        }
        XCTAssertThrowsError(try service.autoParamsForCoordinates(0, 0)) { error in
            XCTAssertEqual(error as? IslamicKitError, .directoryRequired)
        }
        XCTAssertThrowsError(try service.timingsByCoordinatesAuto(0, 0, date: april24))
    }

    func testAutoParamsForCityEntry() {
        let entry = CityEntry(
            id: 1, nameEn: "Cairo", nameAr: "القاهرة", countryId: 66, countryNameEn: "Egypt", countryNameAr: "مصر",
            isoCode: "EG", coordinates: Coordinates(30.06263, 31.24967), utcOffset: UTCOffset(hours: 2),
            timeZoneId: "Africa/Cairo", calculationMethodId: 5
        )
        let params = service.autoParamsForCityEntry(entry)
        XCTAssertEqual(params.method, .egypt)
        XCTAssertEqual(params.school, .standard)
        XCTAssertEqual(params.timezoneName, "Africa/Cairo")
        XCTAssertEqual(params.utcOffset, UTCOffset(hours: 2))
        let unmapped = CityEntry(
            id: 2, nameEn: "Lahore", nameAr: "", countryId: 1, countryNameEn: "Pakistan", countryNameAr: "",
            isoCode: "PK", coordinates: Coordinates(31.5, 74.3), utcOffset: UTCOffset(hours: 5)
        )
        XCTAssertEqual(service.autoParamsForCityEntry(unmapped).method, .karachi)
        XCTAssertEqual(service.autoParamsForCityEntry(unmapped).school, .hanafi)
    }

    func testDirectoryPortIsUsedForCoordinatesAuto() throws {
        struct StubDirectory: CityDirectory {
            let entry: CityEntry
            func countries(query: String?) -> [CountryInfo] { [] }
            func country(_ countryId: Int) -> CountryInfo? { nil }
            func citiesInCountry(_ countryId: Int, query: String?, limit: Int, offset: Int) -> [CityEntry] { [] }
            func searchCities(query: String?, limit: Int, offset: Int) -> [CityEntry] { [] }
            func nearestCity(_ latitude: Double, _ longitude: Double) -> CityEntry? { entry }
            func timeZonesForCountry(_ countryId: Int) -> [TimeZoneInfo] { [] }
        }
        let entry = CityEntry(
            id: 1, nameEn: "Makkah", nameAr: "مكة", countryId: 1, countryNameEn: "Saudi Arabia", countryNameAr: "",
            isoCode: "SA", coordinates: makkah, utcOffset: UTCOffset(hours: 3), timeZoneId: "Asia/Riyadh", calculationMethodId: 4
        )
        let withDirectory = PrayerTimesService(directory: StubDirectory(entry: entry))
        let params = try XCTUnwrap(withDirectory.autoParamsForCoordinates(21.4, 39.8))
        XCTAssertEqual(params.method, .makkah)
        let result = try XCTUnwrap(withDirectory.timingsByCoordinatesAuto(21.4, 39.8, date: CivilDate(year: 2026, month: 4, day: 20)))
        XCTAssertEqual(result.meta.timezone, "Asia/Riyadh")
        XCTAssertEqual(gapMinutes(result), 90)
        XCTAssertEqual(withDirectory.directory?.countries().count, 0)
    }

    // MARK: Date block and meta

    func testDateBlockAndMeta() throws {
        let r = try service.timings(april24, london, londonParams.with { $0.timezoneName = "Europe/London" })
        XCTAssertEqual(r.date.readable, "24 Apr 2014")
        XCTAssertEqual(r.date.timestamp, 1398297600 - 3600)
        XCTAssertEqual(r.date.gregorian.weekdayEn, "Thursday")
        XCTAssertEqual(r.date.gregorian.monthEn, "April")
        XCTAssertEqual(r.date.gregorian.formatted, "24-04-2014")
        XCTAssertEqual(r.date.hijri.formatted, "24-06-1435")
        XCTAssertEqual(r.date.hijri.weekdayAr, "الخميس")
        XCTAssertEqual(r.meta.timezone, "Europe/London")
        XCTAssertEqual(r.meta.method, .isna)
        XCTAssertEqual(r.meta.methodParams, CalculationMethod.isna.params)
        XCTAssertEqual(r.meta.latitudeAdjustmentMethod, .middleOfNight)
        XCTAssertEqual(r.meta.offsets[.fajr], 0)
        let negative = try service.timings(april24, raleigh, raleighParams)
        XCTAssertEqual(negative.meta.timezone, "UTC-04:00")
        XCTAssertEqual(negative.date.timestamp, 1398297600 + 4 * 3600)
        XCTAssertEqual(try service.timings(april24, london).meta.timezone, "UTC")
    }

    func testCustomMethodAndOverrides() throws {
        let custom = CalculationParameters(
            method: .custom,
            customMethod: MethodParams(fajrAngle: 18, ishaAngle: 17, adjustments: MethodAdjustments(dhuhr: 1)),
            utcOffset: UTCOffset(hours: 1)
        )
        let r = try service.timings(april24, london, custom)
        let mwl = try service.timings(april24, london, CalculationParameters(method: .mwl, utcOffset: UTCOffset(hours: 1)))
        XCTAssertEqual(r.formatted(.fajr), mwl.formatted(.fajr))
        XCTAssertEqual(r.formatted(.isha), mwl.formatted(.isha))
        XCTAssertEqual(r.meta.methodParams.fajrAngle, 18)
        XCTAssertEqual(custom.effectiveParams.ishaAngle, 17)
        XCTAssertEqual(CalculationParameters(method: .custom).effectiveParams, CalculationMethod.custom.params)

        let shadow = try service.timings(april24, london, londonParams.with { $0.asrShadowFactor = 2 })
        let hanafi = try service.timings(april24, london, londonParams.with { $0.school = .hanafi })
        XCTAssertEqual(shadow.formatted(.asr), hanafi.formatted(.asr))
        XCTAssertNotEqual(shadow.formatted(.asr), "16:56")

        let minutes = try service.timings(april24, london, londonParams.with { $0.imsakMinutes = 20; $0.dhuhrMinutes = 2 })
        XCTAssertEqual(minutes.formatted(.imsak), "03:37")
        XCTAssertEqual(minutes.formatted(.dhuhr), "13:02")

        let tehran = try service.timings(april24, Coordinates(35.6891975, 51.3889736),
                                         CalculationParameters(method: .tehran, utcOffset: UTCOffset(hours: 4, minutes: 30)))
        XCTAssertGreaterThan(tehran.time(.maghrib).hours!, tehran.time(.sunset).hours!)
        XCTAssertEqual(tehran.meta.midnightMode, .jafari)
        XCTAssertEqual(tehran.formatted(.sunset, .iso8601).suffix(6), "+04:30")
    }

    func testHighLatitudeRulesDiffer() throws {
        let stockholm = Coordinates(59.3293, 18.0686)
        let solstice = CivilDate(year: 2024, month: 6, day: 21)
        var seen = Set<String>()
        for rule in [HighLatitudeRule.middleOfNight, .oneSeventh, .angleBased] {
            let r = try service.timings(solstice, stockholm, CalculationParameters(highLatitudeRule: rule, utcOffset: UTCOffset(hours: 2)))
            seen.insert(r.formatted(.fajr))
            XCTAssertEqual(r.meta.latitudeAdjustmentMethod, rule)
        }
        XCTAssertEqual(seen.count, 3)
    }
}
