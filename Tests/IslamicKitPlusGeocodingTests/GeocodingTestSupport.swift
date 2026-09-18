import Foundation
import XCTest
@testable import IslamicKitPlusGeocoding

/// One read-only connection to the bundled database, shared by every test
/// class so the 37 MB file is opened once per process.
enum TestDatabase {
    static let shared: SQLiteDatabase = {
        do {
            return try SQLiteDatabase(path: try BundledCityDatabase.url().path)
        } catch {
            fatalError("cannot open the bundled database: \(error)")
        }
    }()

    static let geocoder = SqliteCityGeocoder(database: shared)
    static let directory = SqliteCityDirectory(database: shared)
}

enum GeocodingFixtures {
    /// Decodes `Fixtures/conformance/<name>.json` from the test bundle.
    static func load<T: Decodable>(_ name: String, as type: T.Type = T.self) throws -> T {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/conformance"),
            "missing conformance fixture \(name).json"
        )
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    /// Parses the `yyyy-mm-dd` form the fixtures use for civil dates.
    static func date(_ iso: String) -> CivilDate {
        let parts = iso.split(separator: "-").map { Int($0)! }
        return CivilDate(year: parts[0], month: parts[1], day: parts[2])
    }
}

/// `XCTAssertEqual` that only touches XCTest on a mismatch.
func assertSame<T: Equatable>(
    _ actual: T,
    _ expected: T,
    _ context: @autoclosure () -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if actual != expected {
        XCTFail("\(context()): expected \(expected) got \(actual)", file: file, line: line)
    }
}

func multiset<T: Hashable>(_ items: [T]) -> [T: Int] {
    var out = [T: Int]()
    for item in items { out[item, default: 0] += 1 }
    return out
}

/// The generator's `_paramsJson`, compared field by field against a
/// `CalculationParameters`.
struct FixtureParams: Decodable {
    let method: String
    let customMethod: JSONNull?
    let school: String
    let asrShadowFactor: Double?
    let midnightMode: String?
    let highLatitudeRule: String
    let utcOffsetSeconds: Int
    let elevation: Double
    let shafaq: String
    let tune: String
    let imsakMinutes: Int
    let dhuhrMinutes: Int
    let calendarMethod: String
    let timezoneName: String?

    /// The directory fixtures never carry a custom method; decoding fails
    /// loudly if that ever changes.
    struct JSONNull: Decodable {
        init(from decoder: Decoder) throws {
            guard try decoder.singleValueContainer().decodeNil() else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "expected null"))
            }
        }
    }

    func assertMatches(_ p: CalculationParameters, _ context: String, file: StaticString = #filePath, line: UInt = #line) {
        assertSame(p.method.code, method, "\(context) method", file: file, line: line)
        assertSame(p.customMethod, nil, "\(context) customMethod", file: file, line: line)
        assertSame(p.school.metaValue, school, "\(context) school", file: file, line: line)
        assertSame(p.asrShadowFactor, asrShadowFactor, "\(context) asrShadowFactor", file: file, line: line)
        assertSame(p.midnightMode?.metaValue, midnightMode, "\(context) midnightMode", file: file, line: line)
        assertSame(p.highLatitudeRule.metaValue, highLatitudeRule, "\(context) highLatitudeRule", file: file, line: line)
        assertSame(p.utcOffset.seconds, utcOffsetSeconds, "\(context) utcOffsetSeconds", file: file, line: line)
        assertSame(p.elevation, elevation, "\(context) elevation", file: file, line: line)
        assertSame(p.shafaq.code, shafaq, "\(context) shafaq", file: file, line: line)
        assertSame(p.tune.csv, tune, "\(context) tune", file: file, line: line)
        assertSame(p.imsakMinutes, imsakMinutes, "\(context) imsakMinutes", file: file, line: line)
        assertSame(p.dhuhrMinutes, dhuhrMinutes, "\(context) dhuhrMinutes", file: file, line: line)
        assertSame(p.calendarMethod.code, calendarMethod, "\(context) calendarMethod", file: file, line: line)
        assertSame(p.timezoneName, timezoneName, "\(context) timezoneName", file: file, line: line)
    }
}

/// The generator's `_entryJson` for a `CityEntry`.
struct FixtureEntry: Decodable, Hashable {
    let id: Int
    let nameEn: String
    let nameAr: String
    let countryId: Int
    let countryNameEn: String
    let countryNameAr: String
    let isoCode: String
    let lat: Double
    let lng: Double
    let offsetMinutes: Int
    let timeZoneId: String?
    let calculationMethodId: Int?
    let calculationMethod: String?

    init(_ e: CityEntry) {
        id = e.id
        nameEn = e.nameEn
        nameAr = e.nameAr
        countryId = e.countryId
        countryNameEn = e.countryNameEn
        countryNameAr = e.countryNameAr
        isoCode = e.isoCode
        lat = e.coordinates.latitude
        lng = e.coordinates.longitude
        offsetMinutes = e.utcOffset.totalMinutes
        timeZoneId = e.timeZoneId
        calculationMethodId = e.calculationMethodId
        calculationMethod = e.calculationMethod?.code
    }
}

/// The generator's `_countryJson` for a `CountryInfo`.
struct FixtureCountry: Decodable, Hashable {
    let id: Int
    let nameEn: String
    let nameAr: String
    let isoCode: String
    let calculationMethodId: Int?
    let calculationMethod: String?

    init(_ c: CountryInfo) {
        id = c.id
        nameEn = c.nameEn
        nameAr = c.nameAr
        isoCode = c.isoCode
        calculationMethodId = c.calculationMethodId
        calculationMethod = c.calculationMethod?.code
    }
}

/// A geocoder result reduced to the fields the fixtures record.
struct GeocoderResultKey: Hashable, CustomStringConvertible, Decodable {
    let name: String
    let nameAr: String?
    let country: String
    let state: String?
    let lat: Double
    let lng: Double
    let offsetMinutes: Int

    init(_ city: City) {
        name = city.name
        nameAr = city.nameAr
        country = city.country
        state = city.state
        lat = city.coordinates.latitude
        lng = city.coordinates.longitude
        offsetMinutes = city.utcOffset.totalMinutes
    }

    var description: String {
        "\(name)/\(nameAr ?? "-")/\(country)/\(state ?? "-")/\(lat)/\(lng)/\(offsetMinutes)"
    }
}
