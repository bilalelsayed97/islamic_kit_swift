import XCTest
import IslamicKitPlus

/// The published parameters for every method, asserted as a table so a change
/// to any angle or correction has to be made deliberately.
final class MethodTableTests: XCTestCase {
    // fajr angle, isha angle (nil when interval), isha interval minutes.
    private let expected: [CalculationMethod: (Double, Double?, Int?)] = [
        .karachi: (18, 18, nil),
        .isna: (15, 15, nil),
        .mwl: (18, 17, nil),
        .makkah: (18.5, nil, 90),
        .egypt: (19.5, 17.5, nil),
        .tehran: (17.7, 14, nil),
        .gulf: (19.5, nil, 90),
        .kuwait: (18, 17.5, nil),
        .qatar: (18, nil, 90),
        .singapore: (20, 18, nil),
        .france: (12, 12, nil),
        .turkey: (18, 17, nil),
        .russia: (16, 15, nil),
        .moonsighting: (18, 18, nil),
        .dubai: (18.2, 18.2, nil),
        .jakim: (20, 18, nil),
        .tunisia: (18, 18, nil),
        .algeria: (18, 17, nil),
        .kemenag: (20, 18, nil),
        .morocco: (18, 17, nil),
        .portugal: (18, nil, 77),
        .jordan: (18.5, nil, 90),
        .oman: (18.5, nil, 90),
        .munich: (18, 17, nil),
        .maldives: (18, 17, nil),
        .canada: (15, 15, nil),
        .tajikistan: (18, 17, nil),
        .vienna: (18, 17, nil),
        .belgium: (18, 17, nil),
        .sudan: (19.5, 17.5, nil),
        .libya: (19.5, 17.5, nil),
        .iraq: (18, 17, nil),
        .luxembourg: (18, 17, nil),
        .custom: (15, 15, nil),
    ]

    func testTableCoversEveryMethod() {
        XCTAssertEqual(Set(expected.keys), Set(CalculationMethod.allCases))
    }

    func testMethodParameters() {
        for (method, values) in expected {
            let (fajr, isha, interval) = values
            XCTAssertEqual(method.params.fajrAngle, fajr, method.code)
            XCTAssertEqual(method.params.ishaAngle, isha, method.code)
            XCTAssertEqual(method.params.ishaMinutesAfterMaghrib, interval, method.code)
        }
    }

    func testDeclarationOrderMatchesDart() {
        XCTAssertEqual(CalculationMethod.allCases.first, .karachi)
        XCTAssertEqual(CalculationMethod.allCases.last, .custom)
        XCTAssertEqual(CalculationMethod.allCases.count, 34)
    }

    // MARK: Method corrections

    func testAuthoritiesThatPublishDhuhrAMinuteLate() {
        let plusOne: Set<CalculationMethod> = [.karachi, .isna, .mwl, .egypt, .singapore]
        for method in plusOne {
            XCTAssertEqual(method.params.adjustments.dhuhr, 1, method.code)
        }
    }

    func testDubaiShiftsSunriseDhuhrAsrAndMaghrib() {
        let a = CalculationMethod.dubai.params.adjustments
        XCTAssertEqual(a.sunrise, -3)
        XCTAssertEqual(a.dhuhr, 3)
        XCTAssertEqual(a.asr, 3)
        XCTAssertEqual(a.maghrib, 3)
    }

    func testMoonsightingShiftsDhuhrAndMaghrib() {
        let a = CalculationMethod.moonsighting.params.adjustments
        XCTAssertEqual(a.dhuhr, 5)
        XCTAssertEqual(a.maghrib, 3)
    }

    func testCanadaIsNotAnAliasOfISNA() {
        XCTAssertTrue(CalculationMethod.canada.params.adjustments.isEmpty)
        XCTAssertFalse(CalculationMethod.isna.params.adjustments.isEmpty)
    }

    func testOnlyUmmAlQuraVariesIshaInRamadan() {
        let varying = CalculationMethod.allCases.filter { $0.params.hasRamadanIshaInterval }
        XCTAssertEqual(varying, [.makkah])
        XCTAssertEqual(CalculationMethod.makkah.params.ramadanIshaMinutesAfterMaghrib, 120)
    }

    // MARK: Method ids

    func testIdsAreUnique() {
        let ids = CalculationMethod.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testAladhanNumberedMethodsKeepTheirId() {
        XCTAssertEqual(CalculationMethod.fromId(1), .karachi)
        XCTAssertEqual(CalculationMethod.fromId(3), .mwl)
        XCTAssertEqual(CalculationMethod.fromId(4), .makkah)
        XCTAssertEqual(CalculationMethod.fromId(23), .jordan)
        XCTAssertEqual(CalculationMethod.fromId(99), .custom)
    }

    func testPackageOnlyMethodsAreNumberedFrom101() {
        let extra = CalculationMethod.allCases.filter { !$0.isAladhanMethod }
        XCTAssertEqual(extra.count, 11)
        XCTAssertTrue(extra.allSatisfy { $0.id >= 101 })
    }

    func testUnknownIdFallsBackToMWL() {
        XCTAssertEqual(CalculationMethod.fromId(-1), .mwl)
        XCTAssertEqual(CalculationMethod.fromCode("NOPE"), .mwl)
    }

    // MARK: Enum fallbacks

    func testOtherEnumFallbacks() {
        XCTAssertEqual(AsrSchool.fromAladhanId(7), .standard)
        XCTAssertEqual(AsrSchool.fromAladhanId(1), .hanafi)
        XCTAssertEqual(MidnightMode.fromAladhanId(9), .standard)
        XCTAssertEqual(HighLatitudeRule.fromAladhanId(42), .angleBased)
        XCTAssertEqual(HighLatitudeRule.fromAladhanId(1), .middleOfNight)
        XCTAssertEqual(Shafaq.fromCode("nope"), .general)
        XCTAssertEqual(CalendarMethod.fromCode("nope"), .hjcosa)
        XCTAssertEqual(CalendarMethod.fromCode("UAQ"), .uaq)
        XCTAssertNil(Prayer(key: "Nope"))
        XCTAssertEqual(Prayer(key: "Firstthird"), .firstThird)
        XCTAssertEqual(Prayer.allCases.map(\.key),
                       ["Imsak", "Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha", "Midnight", "Firstthird", "Lastthird"])
        XCTAssertEqual(Prayer.firstThird.nameEn, "First Third")
        XCTAssertEqual(Prayer.dhuhr.nameAr, "الظهر")
        XCTAssertEqual(HighLatitudeRule.middleOfNight.metaValue, "MIDDLE_OF_THE_NIGHT")
    }

    func testLocalizationIsWired() {
        XCTAssertEqual(CalculationMethod.mwl.title(.en), "Muslim World League")
        XCTAssertEqual(AsrSchool.hanafi.title(.ar), "الحنفي")
        XCTAssertEqual(Language.ar.title(.en), "Arabic")
    }

    // MARK: Bundled database method map

    func testDatabaseIdsResolveToTheirOwnAuthority() {
        let cases: [Int: CalculationMethod] = [
            1: .karachi, 2: .isna, 3: .mwl, 4: .makkah, 5: .egypt, 6: .dubai,
            7: .kuwait, 8: .qatar, 9: .singapore, 17: .oman, 20: .canada, 28: .tehran,
        ]
        for (id, method) in cases {
            XCTAssertEqual(BundledMethodMap.methodForBundledId(id), method, "\(id)")
        }
    }

    func testMapCoversContiguousRange() {
        XCTAssertEqual(Set(BundledMethodMap.knownIds), Set(1...30))
    }

    func testUnknownIdHasNoMethodButDefaultedOneIsMWL() {
        XCTAssertNil(BundledMethodMap.methodForBundledId(999))
        XCTAssertNil(BundledMethodMap.methodForBundledId(nil))
        XCTAssertEqual(BundledMethodMap.methodForBundledIdOrDefault(999), .mwl)
        let country = CountryInfo(id: 1, nameEn: "X", nameAr: "X", isoCode: "XX", calculationMethodId: 7)
        XCTAssertEqual(country.calculationMethod, .kuwait)
    }
}
