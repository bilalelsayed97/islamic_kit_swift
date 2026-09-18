import XCTest
@testable import IslamicKitPlus

/// `localization.json`: every enum's ids, codes and EN/AR strings, the
/// `Localizer` tables, the lookup fallbacks, `LocationDefaults` and
/// `BundledMethodMap`.
final class ConformanceLocalizationTests: XCTestCase {
    private struct L10n: Decodable {
        let name: String
        let titleEn: String
        let titleAr: String
        let descriptionEn: String
        let descriptionAr: String
    }

    private struct MethodEntry: Decodable {
        let name: String
        let titleEn: String
        let titleAr: String
        let descriptionEn: String
        let descriptionAr: String
        let id: Int
        let code: String
        let methodName: String
        let usesMoonsighting: Bool
        let isAladhanMethod: Bool
        let params: FixtureMethodParams
    }

    private struct SchoolEntry: Decodable {
        let name: String
        let titleEn: String
        let titleAr: String
        let descriptionEn: String
        let descriptionAr: String
        let aladhanId: Int
        let metaValue: String
        let shadowFactor: Int
    }

    private struct IdEntry: Decodable {
        let name: String
        let titleEn: String
        let titleAr: String
        let descriptionEn: String
        let descriptionAr: String
        let aladhanId: Int
        let metaValue: String
    }

    private struct CodeEntry: Decodable {
        let name: String
        let titleEn: String
        let titleAr: String
        let descriptionEn: String
        let descriptionAr: String
        let code: String
    }

    private struct PrayerEntry: Decodable {
        let name: String
        let titleEn: String
        let titleAr: String
        let descriptionEn: String
        let descriptionAr: String
        let key: String
        let nameEn: String
        let nameAr: String
    }

    private struct Name: Decodable {
        let en: String
        let ar: String
    }

    private struct LocalizerTables: Decodable {
        let islamicMonths: [String: Name]
        let hijriWeekdays: [String: Name]
        let gregorianMonths: [String: Name]
        let gregorianWeekdays: [String: Name]
        let monthAbbrEn: [String]
    }

    private struct Defaults: Decodable {
        let method: String
        let school: String
    }

    private struct File: Decodable {
        let calculationMethods: [MethodEntry]
        let asrSchools: [SchoolEntry]
        let midnightModes: [IdEntry]
        let highLatitudeRules: [IdEntry]
        let shafaqs: [CodeEntry]
        let calendarMethods: [CodeEntry]
        let timeFormats: [CodeEntry]
        let prayers: [PrayerEntry]
        let languages: [L10n]
        let localizer: LocalizerTables
        let fallbacks: [String: String]
        let locationDefaults: [String: Defaults]
        let bundledMethodMap: [String: String]
    }

    private static let file: File = try! ConformanceFixtures.load("localization")

    /// Compares an enum's Dart `name` and its four localized strings.
    private func assertL10n<E>(
        _ value: E,
        name: String, titleEn: String, titleAr: String, descriptionEn: String, descriptionAr: String,
        title: (E, Language) -> String, description: (E, Language) -> String
    ) {
        let c = "\(E.self).\(name)"
        assertSame("\(value)", name, "\(c) name")
        assertSame(title(value, .en), titleEn, "\(c) titleEn")
        assertSame(title(value, .ar), titleAr, "\(c) titleAr")
        assertSame(description(value, .en), descriptionEn, "\(c) descriptionEn")
        assertSame(description(value, .ar), descriptionAr, "\(c) descriptionAr")
    }

    func testCalculationMethods() {
        let entries = Self.file.calculationMethods
        XCTAssertEqual(entries.count, CalculationMethod.allCases.count)
        for (m, e) in zip(CalculationMethod.allCases, entries) {
            assertL10n(m, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(m.id, e.id, "\(e.name) id")
            assertSame(m.code, e.code, "\(e.name) code")
            assertSame(m.methodName, e.methodName, "\(e.name) methodName")
            assertSame(m.usesMoonsighting, e.usesMoonsighting, "\(e.name) usesMoonsighting")
            assertSame(m.isAladhanMethod, e.isAladhanMethod, "\(e.name) isAladhanMethod")
            assertMethodParams(m.params, e.params, "\(e.name) params")
        }
    }

    func testAsrSchools() {
        let entries = Self.file.asrSchools
        XCTAssertEqual(entries.count, AsrSchool.allCases.count)
        for (v, e) in zip(AsrSchool.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.aladhanId, e.aladhanId, "\(e.name) aladhanId")
            assertSame(v.metaValue, e.metaValue, "\(e.name) metaValue")
            assertSame(v.shadowFactor, e.shadowFactor, "\(e.name) shadowFactor")
        }
    }

    func testMidnightModes() {
        let entries = Self.file.midnightModes
        XCTAssertEqual(entries.count, MidnightMode.allCases.count)
        for (v, e) in zip(MidnightMode.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.aladhanId, e.aladhanId, "\(e.name) aladhanId")
            assertSame(v.metaValue, e.metaValue, "\(e.name) metaValue")
        }
    }

    func testHighLatitudeRules() {
        let entries = Self.file.highLatitudeRules
        XCTAssertEqual(entries.count, HighLatitudeRule.allCases.count)
        for (v, e) in zip(HighLatitudeRule.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.aladhanId, e.aladhanId, "\(e.name) aladhanId")
            assertSame(v.metaValue, e.metaValue, "\(e.name) metaValue")
        }
    }

    func testShafaqs() {
        let entries = Self.file.shafaqs
        XCTAssertEqual(entries.count, Shafaq.allCases.count)
        for (v, e) in zip(Shafaq.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.code, e.code, "\(e.name) code")
        }
    }

    func testCalendarMethods() {
        let entries = Self.file.calendarMethods
        XCTAssertEqual(entries.count, CalendarMethod.allCases.count)
        for (v, e) in zip(CalendarMethod.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.code, e.code, "\(e.name) code")
        }
    }

    func testTimeFormats() {
        let entries = Self.file.timeFormats
        XCTAssertEqual(entries.count, TimeFormat.allCases.count)
        for (v, e) in zip(TimeFormat.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.code, e.code, "\(e.name) code")
        }
    }

    func testPrayers() {
        let entries = Self.file.prayers
        XCTAssertEqual(entries.count, Prayer.allCases.count)
        for (v, e) in zip(Prayer.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
            assertSame(v.key, e.key, "\(e.name) key")
            assertSame(v.nameEn, e.nameEn, "\(e.name) nameEn")
            assertSame(v.nameAr, e.nameAr, "\(e.name) nameAr")
        }
    }

    func testLanguages() {
        let entries = Self.file.languages
        XCTAssertEqual(entries.count, Language.allCases.count)
        for (v, e) in zip(Language.allCases, entries) {
            assertL10n(v, name: e.name, titleEn: e.titleEn, titleAr: e.titleAr,
                       descriptionEn: e.descriptionEn, descriptionAr: e.descriptionAr,
                       title: { $0.title($1) }, description: { $0.description($1) })
        }
    }

    private func assertTable(_ actual: [Int: LocalizedName], _ expected: [String: Name], _ context: String) {
        assertSame(actual.count, expected.count, "\(context) count")
        for (key, name) in expected {
            guard let value = actual[Int(key)!] else {
                XCTFail("\(context): missing \(key)")
                continue
            }
            assertSame(value.en, name.en, "\(context)[\(key)].en")
            assertSame(value.ar, name.ar, "\(context)[\(key)].ar")
        }
    }

    func testLocalizerTables() {
        let l = Self.file.localizer
        assertTable(Localizer.islamicMonths, l.islamicMonths, "islamicMonths")
        assertTable(Localizer.hijriWeekdays, l.hijriWeekdays, "hijriWeekdays")
        assertTable(Localizer.gregorianMonths, l.gregorianMonths, "gregorianMonths")
        assertTable(Localizer.gregorianWeekdays, l.gregorianWeekdays, "gregorianWeekdays")
        XCTAssertEqual(Localizer.monthAbbrEn, l.monthAbbrEn)
    }

    func testFallbacks() {
        let f = Self.file.fallbacks
        XCTAssertEqual(f.count, 7)
        XCTAssertEqual(CalculationMethod.fromId(-1).code, f["calculationMethodFromId(-1)"])
        XCTAssertEqual(CalculationMethod.fromCode("NOPE").code, f["calculationMethodFromCode(NOPE)"])
        XCTAssertEqual(AsrSchool.fromAladhanId(9).metaValue, f["asrSchoolFromAladhanId(9)"])
        XCTAssertEqual(MidnightMode.fromAladhanId(9).metaValue, f["midnightModeFromAladhanId(9)"])
        XCTAssertEqual(HighLatitudeRule.fromAladhanId(9).metaValue, f["highLatitudeRuleFromAladhanId(9)"])
        XCTAssertEqual(Shafaq.fromCode("x").code, f["shafaqFromCode(x)"])
        XCTAssertEqual(CalendarMethod.fromCode("x").code, f["calendarMethodFromCode(x)"])
    }

    func testLocationDefaults() {
        let defaults = Self.file.locationDefaults
        // Every ISO code known to the database, plus the unknown `XX` and the
        // lower-case `gb`.
        XCTAssertEqual(defaults.count, CountryIsoMap.isoToId.count + 2)
        for iso in CountryIsoMap.isoToId.keys {
            XCTAssertNotNil(defaults[iso], "fixture lacks \(iso)")
        }
        for (iso, d) in defaults {
            assertSame(LocationDefaults.methodForCountry(iso).code, d.method, "locationDefaults[\(iso)].method")
            assertSame(LocationDefaults.schoolForCountry(iso).metaValue, d.school, "locationDefaults[\(iso)].school")
        }
    }

    func testBundledMethodMap() {
        let map = Self.file.bundledMethodMap
        XCTAssertEqual(map.count, BundledMethodMap.knownIds.count)
        for id in BundledMethodMap.knownIds {
            assertSame(BundledMethodMap.methodForBundledId(id)?.code, map["\(id)"], "bundledMethodMap[\(id)]")
        }
    }
}
