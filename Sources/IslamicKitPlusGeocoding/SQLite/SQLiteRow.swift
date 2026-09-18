/// A value bound to a `?` placeholder, typed the way Dart's `sqlite3` binds
/// its arguments (`int` → INTEGER, `double` → REAL, `String` → TEXT).
public enum SQLiteBinding: Hashable, Sendable {
    case int(Int)
    case double(Double)
    case text(String)
    case null
}

extension SQLiteBinding: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral,
    ExpressibleByStringLiteral, ExpressibleByNilLiteral
{
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(stringLiteral value: String) { self = .text(value) }
    public init(nilLiteral: ()) { self = .null }
}

/// A column value copied out of a stepped statement.
public enum SQLiteValue: Hashable, Sendable {
    case null
    case int(Int64)
    case double(Double)
    case text(String)
    case blob([UInt8])
}

/// One result row, snapshotted by column name so it outlives the statement
/// it came from (statements are cached and reused under the database lock).
public struct SQLiteRow: Hashable, Sendable {
    private let values: [String: SQLiteValue]

    init(values: [String: SQLiteValue]) {
        self.values = values
    }

    /// The raw value of `column`, or `nil` when the row has no such column.
    public subscript(column: String) -> SQLiteValue? { values[column] }

    /// Whether `column` holds SQL NULL (or is absent).
    public func isNull(_ column: String) -> Bool {
        values[column].map { $0 == .null } ?? true
    }

    /// The integer value of `column`; REAL is truncated, NULL/absent/text is `nil`.
    public func int(_ column: String) -> Int? {
        switch values[column] {
        case .int(let i)?: return Int(i)
        case .double(let d)?: return d.isFinite ? Int(d) : nil
        default: return nil
        }
    }

    /// The floating-point value of `column`; INTEGER is widened, NULL/absent/text is `nil`.
    public func double(_ column: String) -> Double? {
        switch values[column] {
        case .int(let i)?: return Double(i)
        case .double(let d)?: return d
        default: return nil
        }
    }

    /// The text value of `column`; NULL/absent/non-text is `nil`.
    public func text(_ column: String) -> String? {
        if case .text(let s)? = values[column] { return s }
        return nil
    }
}
