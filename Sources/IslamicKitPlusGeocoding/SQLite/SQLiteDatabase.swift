import Foundation
import SQLite3

/// A minimal read-only connection over the system SQLite library.
///
/// The bundled database is opened in place (`immutable=1`, read-only, no
/// journal sidecars), every call is serialized on an `NSLock`, and prepared
/// statements are cached by SQL text, so the class is safe to share across
/// threads — calls simply queue on the one connection.
public final class SQLiteDatabase: @unchecked Sendable {
    private let handle: OpaquePointer
    private let lock = NSLock()
    private var statements = [String: SQLiteStatement]()

    /// The path the connection was opened from.
    public let path: String

    /// Opens `path` read-only.
    ///
    /// Tries a `file:` URI with `immutable=1` first (no locking, no journal
    /// probing — right for a resource inside an app bundle) and falls back
    /// to a plain read-only open. Throws `SQLiteError` when neither works,
    /// including for a missing file.
    public init(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw SQLiteError(code: SQLITE_CANTOPEN, message: "no database at \(path)")
        }
        self.path = path
        let readOnly = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        do {
            handle = try SQLiteDatabase.open(SQLiteDatabase.immutableURI(path), flags: readOnly | SQLITE_OPEN_URI)
        } catch {
            handle = try SQLiteDatabase.open(path, flags: readOnly)
        }
    }

    deinit {
        // Statements must be finalized before the connection closes.
        statements.removeAll()
        sqlite3_close_v2(handle)
    }

    /// Runs `sql` with `bindings` and returns every row.
    public func query(_ sql: String, _ bindings: [SQLiteBinding] = []) throws -> [SQLiteRow] {
        try execute(sql, bindings) { statement in
            var rows = [SQLiteRow]()
            while try statement.step() {
                rows.append(statement.currentRow())
            }
            return rows
        }
    }

    /// The first column of the first row of `sql`, e.g. for `PRAGMA
    /// user_version` or `SELECT COUNT(*)`; `nil` when there is no row.
    public func scalar(_ sql: String, _ bindings: [SQLiteBinding] = []) throws -> SQLiteValue? {
        try execute(sql, bindings) { statement in
            guard try statement.step(), let column = statement.columnNames.first else { return nil }
            return statement.currentRow()[column]
        }
    }

    // MARK: - Internals

    /// Binds and runs a cached statement under the lock, resetting it after
    /// `consume` so the next caller finds it clean.
    private func execute<T>(
        _ sql: String,
        _ bindings: [SQLiteBinding],
        _ consume: (SQLiteStatement) throws -> T
    ) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepared(sql)
        defer { statement.reset() }
        try statement.bind(bindings)
        return try consume(statement)
    }

    private func prepared(_ sql: String) throws -> SQLiteStatement {
        if let cached = statements[sql] { return cached }
        let statement = try SQLiteStatement(database: handle, sql: sql)
        statements[sql] = statement
        return statement
    }

    private static func open(_ filename: String, flags: Int32) throws -> OpaquePointer {
        var db: OpaquePointer?
        let rc = sqlite3_open_v2(filename, &db, flags, nil)
        guard rc == SQLITE_OK, let opened = db else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "sqlite3_open_v2 failed"
            if let db = db { sqlite3_close_v2(db) }
            throw SQLiteError(code: rc, message: message)
        }
        // A URI open reports a corrupt or foreign file only on first use;
        // probe the schema so the failure surfaces here, where the caller
        // can fall back.
        let probe = sqlite3_exec(opened, "SELECT 1 FROM sqlite_master LIMIT 1", nil, nil, nil)
        guard probe == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(opened))
            sqlite3_close_v2(opened)
            throw SQLiteError(code: probe, message: message)
        }
        return opened
    }

    /// `file:<percent-encoded path>?immutable=1`.
    private static func immutableURI(_ path: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "?#%")
        let encoded = path.addingPercentEncoding(withAllowedCharacters: allowed) ?? path
        return "file:\(encoded)?immutable=1"
    }
}
