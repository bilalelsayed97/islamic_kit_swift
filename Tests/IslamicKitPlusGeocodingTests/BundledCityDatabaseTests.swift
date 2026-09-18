import XCTest
@testable import IslamicKitPlusGeocoding

final class BundledCityDatabaseTests: XCTestCase {
    static let expectedSize = 37_093_376

    func testResourceExistsWithExpectedSize() throws {
        let url = try BundledCityDatabase.url()
        XCTAssertEqual(url.lastPathComponent, "prayer_times.db")
        let size = try XCTUnwrap(FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)
        XCTAssertEqual(size.intValue, Self.expectedSize)
    }

    func testUserVersionIsTwo() throws {
        XCTAssertEqual(BundledCityDatabase.version, "2")
        XCTAssertEqual(try TestDatabase.shared.scalar("PRAGMA user_version"), .int(2))
    }

    func testMaterializeCopiesOnceAndReusesTheFile() throws {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("islamic_kit_swift_tests/\(UUID().uuidString)")
        defer { try? fm.removeItem(at: dir) }

        let first = try BundledCityDatabase.materialize(into: dir)
        XCTAssertEqual(first.lastPathComponent, "islamic_kit_plus_prayer_times_v2.db")
        XCTAssertEqual(first.lastPathComponent, BundledCityDatabase.materializedFileName)
        XCTAssertEqual(try fm.attributesOfItem(atPath: first.path)[.size] as? Int, Self.expectedSize)
        XCTAssertFalse(fm.fileExists(atPath: first.path + ".tmp"))

        // The copy is usable and reports the same schema version.
        XCTAssertEqual(try SQLiteDatabase(path: first.path).scalar("PRAGMA user_version"), .int(2))

        // A second call reuses the existing file instead of copying again.
        let stamp = try fm.attributesOfItem(atPath: first.path)[.modificationDate] as? Date
        let second = try BundledCityDatabase.materialize(into: dir)
        XCTAssertEqual(second, first)
        XCTAssertEqual(try fm.attributesOfItem(atPath: second.path)[.modificationDate] as? Date, stamp)

        // A non-empty file of any size is reused as-is (Dart parity)...
        try Data([0x01]).write(to: first)
        _ = try BundledCityDatabase.materialize(into: dir)
        XCTAssertEqual(try fm.attributesOfItem(atPath: first.path)[.size] as? Int, 1)

        // ...but an empty (interrupted) file is replaced.
        try Data().write(to: first)
        _ = try BundledCityDatabase.materialize(into: dir)
        XCTAssertEqual(try fm.attributesOfItem(atPath: first.path)[.size] as? Int, Self.expectedSize)
    }

    func testBundledOpenersUseTheResource() throws {
        XCTAssertEqual(try SqliteCityGeocoder.bundled().resolve("Cairo", country: "EG")?.country, "EG")
        XCTAssertEqual(try SqliteCityDirectory.bundled().country(65)?.isoCode, "EG")
    }
}
