/// A JSON value whose objects keep insertion order, so that the aladhan
/// envelopes serialize with the same key order as the Dart package.
public indirect enum JSONValue: Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object(JSONObject)

    /// The nested object, if this is one.
    public var object: JSONObject? {
        if case .object(let o) = self { return o }
        return nil
    }

    /// The nested array, if this is one.
    public var array: [JSONValue]? {
        if case .array(let a) = self { return a }
        return nil
    }

    public var string: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    public var int: Int? {
        if case .int(let i) = self { return i }
        return nil
    }

    public var double: Double? {
        switch self {
        case .double(let d): return d
        case .int(let i): return Double(i)
        default: return nil
        }
    }

    public var bool: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    /// `object[key]` shorthand; `nil` when this is not an object or lacks `key`.
    public subscript(key: String) -> JSONValue? {
        object?[key]
    }

    /// `array[index]` shorthand; `nil` when this is not an array.
    public subscript(index: Int) -> JSONValue? {
        guard let a = array, a.indices.contains(index) else { return nil }
        return a[index]
    }

    /// The Dart `jsonEncode` form (compact). `indent` selects Dart's
    /// `JsonEncoder.withIndent` layout instead.
    public func serialized(indent: String? = nil) -> String {
        var out = ""
        JSONSerializer.write(self, indent: indent, depth: 0, into: &out)
        return out
    }
}

/// An insertion-ordered JSON object.
public struct JSONObject: Equatable, Sendable, ExpressibleByDictionaryLiteral {
    public private(set) var keys: [String] = []
    private var storage: [String: JSONValue] = [:]

    public init() {}

    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        for (key, value) in elements { self[key] = value }
    }

    public init(_ pairs: [(String, JSONValue)]) {
        for (key, value) in pairs { self[key] = value }
    }

    /// Ordered `(key, value)` pairs.
    public var entries: [(key: String, value: JSONValue)] {
        keys.map { ($0, storage[$0]!) }
    }

    public var count: Int { keys.count }

    public var isEmpty: Bool { keys.isEmpty }

    /// Assigning to an existing key replaces its value in place; a new key is
    /// appended; assigning `nil` removes the key.
    public subscript(key: String) -> JSONValue? {
        get { storage[key] }
        set {
            if let value = newValue {
                if storage[key] == nil { keys.append(key) }
                storage[key] = value
            } else if storage.removeValue(forKey: key) != nil {
                keys.removeAll { $0 == key }
            }
        }
    }

    public func serialized(indent: String? = nil) -> String {
        JSONValue.object(self).serialized(indent: indent)
    }

    public static func == (lhs: JSONObject, rhs: JSONObject) -> Bool {
        lhs.keys == rhs.keys && lhs.storage == rhs.storage
    }
}

extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral,
    ExpressibleByBooleanLiteral, ExpressibleByNilLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral
{
    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(nilLiteral: ()) { self = .null }
    public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(JSONObject(elements))
    }
}

/// Mirrors Dart's `jsonEncode` / `JsonEncoder.withIndent`: ints without
/// `.0`, doubles via `DartNumberFormatting`, `"`/`\`/control characters
/// escaped, everything else (including `/` and non-ASCII) left raw.
enum JSONSerializer {
    static func write(_ value: JSONValue, indent: String?, depth: Int, into out: inout String) {
        switch value {
        case .string(let s):
            writeString(s, into: &out)
        case .int(let i):
            out += String(i)
        case .double(let d):
            precondition(d.isFinite, "JSON cannot encode a non-finite double (Dart throws JsonUnsupportedObjectError)")
            out += DartNumberFormatting.string(d)
        case .bool(let b):
            out += b ? "true" : "false"
        case .null:
            out += "null"
        case .array(let items):
            if items.isEmpty {
                out += "[]"
                return
            }
            out += "["
            for (i, item) in items.enumerated() {
                if i > 0 { out += "," }
                newline(indent, depth + 1, into: &out)
                write(item, indent: indent, depth: depth + 1, into: &out)
            }
            newline(indent, depth, into: &out)
            out += "]"
        case .object(let object):
            if object.isEmpty {
                out += "{}"
                return
            }
            out += "{"
            for (i, entry) in object.entries.enumerated() {
                if i > 0 { out += "," }
                newline(indent, depth + 1, into: &out)
                writeString(entry.key, into: &out)
                out += indent == nil ? ":" : ": "
                write(entry.value, indent: indent, depth: depth + 1, into: &out)
            }
            newline(indent, depth, into: &out)
            out += "}"
        }
    }

    private static func newline(_ indent: String?, _ depth: Int, into out: inout String) {
        guard let indent = indent else { return }
        out += "\n"
        for _ in 0..<depth { out += indent }
    }

    private static func writeString(_ s: String, into out: inout String) {
        out += "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            default:
                if scalar.value < 0x20 {
                    let hex = String(scalar.value, radix: 16)
                    out += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        out += "\""
    }
}
