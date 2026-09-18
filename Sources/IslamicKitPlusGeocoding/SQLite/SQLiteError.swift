import Foundation

/// An error reported by the SQLite C API, with its result code and message.
public struct SQLiteError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    /// The SQLite result code (`SQLITE_CANTOPEN`, `SQLITE_ERROR`, ...).
    public let code: Int32

    /// The message SQLite attached to the failure.
    public let message: String

    public init(code: Int32, message: String) {
        self.code = code
        self.message = message
    }

    public var description: String { "SQLiteError(\(code): \(message))" }

    public var errorDescription: String? { description }
}
