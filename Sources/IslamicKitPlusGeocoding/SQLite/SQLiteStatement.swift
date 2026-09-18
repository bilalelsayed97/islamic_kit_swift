import Foundation
import SQLite3

/// Tells SQLite to copy bound text instead of keeping our pointer.
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A prepared statement. Not thread-safe on its own: `SQLiteDatabase` owns
/// every instance and only touches it while holding its lock.
final class SQLiteStatement {
    private let handle: OpaquePointer
    private let database: OpaquePointer

    /// Column names in result order, resolved once at prepare time.
    let columnNames: [String]

    init(database: OpaquePointer, sql: String) throws {
        var stmt: OpaquePointer?
        let rc = sqlite3_prepare_v2(database, sql, -1, &stmt, nil)
        guard rc == SQLITE_OK, let prepared = stmt else {
            let message = String(cString: sqlite3_errmsg(database))
            if let s = stmt { sqlite3_finalize(s) }
            throw SQLiteError(code: rc, message: message)
        }
        self.database = database
        handle = prepared
        columnNames = (0..<sqlite3_column_count(prepared)).map {
            String(cString: sqlite3_column_name(prepared, $0))
        }
    }

    deinit {
        sqlite3_finalize(handle)
    }

    /// Binds `values` to the placeholders `?1`, `?2`, ... in order.
    func bind(_ values: [SQLiteBinding]) throws {
        let expected = Int(sqlite3_bind_parameter_count(handle))
        guard values.count == expected else {
            throw SQLiteError(
                code: SQLITE_RANGE,
                message: "statement expects \(expected) bindings, got \(values.count)"
            )
        }
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let rc: Int32
            switch value {
            case .int(let i): rc = sqlite3_bind_int64(handle, index, Int64(i))
            case .double(let d): rc = sqlite3_bind_double(handle, index, d)
            case .text(let s): rc = sqlite3_bind_text(handle, index, s, -1, SQLITE_TRANSIENT)
            case .null: rc = sqlite3_bind_null(handle, index)
            }
            guard rc == SQLITE_OK else { throw error(rc) }
        }
    }

    /// Advances to the next row. Returns `false` once the statement is done.
    func step() throws -> Bool {
        let rc = sqlite3_step(handle)
        switch rc {
        case SQLITE_ROW: return true
        case SQLITE_DONE: return false
        default: throw error(rc)
        }
    }

    /// Resets the statement and clears its bindings so it can run again.
    func reset() {
        sqlite3_reset(handle)
        sqlite3_clear_bindings(handle)
    }

    /// Snapshots the current row.
    func currentRow() -> SQLiteRow {
        var values = [String: SQLiteValue](minimumCapacity: columnNames.count)
        for (index, name) in columnNames.enumerated() {
            values[name] = columnValue(Int32(index))
        }
        return SQLiteRow(values: values)
    }

    private func columnValue(_ column: Int32) -> SQLiteValue {
        switch sqlite3_column_type(handle, column) {
        case SQLITE_INTEGER:
            return .int(sqlite3_column_int64(handle, column))
        case SQLITE_FLOAT:
            return .double(sqlite3_column_double(handle, column))
        case SQLITE_TEXT:
            return .text(String(cString: sqlite3_column_text(handle, column)))
        case SQLITE_BLOB:
            let count = Int(sqlite3_column_bytes(handle, column))
            guard count > 0, let bytes = sqlite3_column_blob(handle, column) else { return .blob([]) }
            return .blob(Array(UnsafeBufferPointer(start: bytes.assumingMemoryBound(to: UInt8.self), count: count)))
        default:
            return .null
        }
    }

    private func error(_ rc: Int32) -> SQLiteError {
        SQLiteError(code: rc, message: String(cString: sqlite3_errmsg(database)))
    }
}
