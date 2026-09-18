import XCTest
import SQLite3
@testable import IslamicKitPlusGeocoding

final class SQLiteWrapperTests: XCTestCase {
    private var db: SQLiteDatabase { TestDatabase.shared }

    func testOpensBundledDatabaseReadOnly() throws {
        XCTAssertEqual(db.path, try BundledCityDatabase.url().path)
        // Writes are refused on a read-only connection.
        XCTAssertThrowsError(try db.query("CREATE TABLE scratch (x INTEGER)")) { error in
            let e = error as? SQLiteError
            XCTAssertEqual(e?.code, SQLITE_READONLY, "\(error)")
        }
    }

    func testMissingFileThrowsCantOpen() {
        XCTAssertThrowsError(try SQLiteDatabase(path: "/nonexistent/dir/prayer_times.db")) { error in
            XCTAssertEqual((error as? SQLiteError)?.code, SQLITE_CANTOPEN)
        }
    }

    func testColumnTypesAndNullDetection() throws {
        let row = try XCTUnwrap(db.query("SELECT 1 AS i, 2.5 AS d, 'x' AS t, NULL AS n, x'0102' AS b").first)
        XCTAssertEqual(row["i"], .int(1))
        XCTAssertEqual(row["d"], .double(2.5))
        XCTAssertEqual(row["t"], .text("x"))
        XCTAssertEqual(row["n"], .null)
        XCTAssertEqual(row["b"], .blob([1, 2]))

        XCTAssertEqual(row.int("i"), 1)
        XCTAssertEqual(row.double("i"), 1.0)
        XCTAssertNil(row.text("i"))
        XCTAssertEqual(row.int("d"), 2)
        XCTAssertEqual(row.double("d"), 2.5)
        XCTAssertEqual(row.text("t"), "x")
        XCTAssertNil(row.int("t"))
        XCTAssertTrue(row.isNull("n"))
        XCTAssertFalse(row.isNull("i"))
        XCTAssertNil(row.int("n"))
        XCTAssertNil(row.double("n"))
        XCTAssertNil(row.text("n"))
        XCTAssertTrue(row.isNull("absent"))
        XCTAssertNil(row["absent"])
    }

    func testBindingsKeepTheirTypes() throws {
        let row = try XCTUnwrap(db.query(
            "SELECT typeof(?) AS a, typeof(?) AS b, typeof(?) AS c, typeof(?) AS d, ? AS v",
            [.int(7), .double(1.5), .text("hi"), .null, .text("round trip")]
        ).first)
        XCTAssertEqual(row.text("a"), "integer")
        XCTAssertEqual(row.text("b"), "real")
        XCTAssertEqual(row.text("c"), "text")
        XCTAssertEqual(row.text("d"), "null")
        XCTAssertEqual(row.text("v"), "round trip")

        // Literal conveniences bind the same way.
        let literals = try XCTUnwrap(db.query("SELECT typeof(?) AS a, typeof(?) AS b, typeof(?) AS c, typeof(?) AS d",
                                              [7, 1.5, "hi", nil]).first)
        XCTAssertEqual([literals.text("a"), literals.text("b"), literals.text("c"), literals.text("d")],
                       ["integer", "real", "text", "null"])
    }

    func testWrongBindingCountThrows() {
        XCTAssertThrowsError(try db.query("SELECT ? AS v", [])) { error in
            XCTAssertEqual((error as? SQLiteError)?.code, SQLITE_RANGE)
        }
    }

    func testStepsMultipleRowsAndReusesCachedStatement() throws {
        let sql = "SELECT country_id FROM prayer_times_country_lookups ORDER BY country_id LIMIT ?"
        let two = try db.query(sql, [2]).compactMap { $0.int("country_id") }
        let three = try db.query(sql, [3]).compactMap { $0.int("country_id") }
        XCTAssertEqual(two, [1, 2])
        XCTAssertEqual(three, [1, 2, 3])
        XCTAssertTrue(try db.query(sql, [0]).isEmpty)
    }

    func testScalar() throws {
        XCTAssertEqual(try db.scalar("SELECT COUNT(*) FROM prayer_times_country_lookups"), .int(251))
        XCTAssertNil(try db.scalar("SELECT 1 WHERE 0"))
    }

    func testSyntaxErrorThrows() {
        XCTAssertThrowsError(try db.query("SELEKT 1")) { error in
            XCTAssertEqual((error as? SQLiteError)?.code, SQLITE_ERROR)
        }
    }

    func testConcurrentQueriesSerializeOnOneConnection() throws {
        let group = DispatchGroup()
        let lock = NSLock()
        var counts = [Int]()
        for i in 0..<16 {
            group.enter()
            DispatchQueue.global().async {
                let rows = (try? self.db.query(
                    "SELECT city_id FROM prayer_times_city_lookups WHERE country_id = ? LIMIT 5", [.int(i + 1)]
                )) ?? []
                lock.lock()
                counts.append(rows.count)
                lock.unlock()
                group.leave()
            }
        }
        group.wait()
        XCTAssertEqual(counts.count, 16)
        XCTAssertTrue(counts.allSatisfy { $0 <= 5 })
    }
}
