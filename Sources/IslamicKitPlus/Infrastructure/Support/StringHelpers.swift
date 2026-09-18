/// Small string helpers shared across the port, each reproducing the exact
/// Dart expression it replaces.
package enum StringHelpers {
    /// Dart `_two(n) = n < 10 ? '0$n' : '$n'` — no handling of negatives.
    package static func two(_ n: Int) -> String {
        n < 10 ? "0\(n)" : "\(n)"
    }

    /// Dart `year.toString().padLeft(4, '0')`.
    package static func padLeft4(_ n: Int) -> String {
        let s = "\(n)"
        return s.count >= 4 ? s : String(repeating: "0", count: 4 - s.count) + s
    }

    /// The whitespace set used for Dart `trim()` and the ECMAScript `\s`
    /// class: the Unicode `White_Space` property plus the BOM (U+FEFF).
    package static func isDartWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x09...0x0D, 0x20, 0x85, 0xA0, 0x1680, 0x2000...0x200A,
             0x2028, 0x2029, 0x202F, 0x205F, 0x3000, 0xFEFF:
            return true
        default:
            return false
        }
    }

    /// Dart `s.trim()`: strips leading and trailing whitespace (see
    /// `isDartWhitespace`).
    package static func dartTrim(_ s: String) -> String {
        let scalars = s.unicodeScalars
        guard let first = scalars.firstIndex(where: { !isDartWhitespace($0) }) else { return "" }
        let last = scalars.lastIndex(where: { !isDartWhitespace($0) })!
        return String(String.UnicodeScalarView(scalars[first...last]))
    }

    /// Dart `s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')`.
    package static func normalize(_ s: String) -> String {
        let lowered = dartTrim(s).lowercased()
        var out = String.UnicodeScalarView()
        var pendingSpace = false
        for scalar in lowered.unicodeScalars {
            if isDartWhitespace(scalar) {
                pendingSpace = true
            } else {
                if pendingSpace {
                    out.append(" ")
                    pendingSpace = false
                }
                out.append(scalar)
            }
        }
        return String(out)
    }

    /// Dart `a.startsWith(b)` on UTF-16 code units.
    package static func utf16HasPrefix(_ a: String, _ b: String) -> Bool {
        a.utf16.starts(with: b.utf16)
    }

    /// Dart `a.contains(b)` on UTF-16 code units.
    package static func utf16Contains(_ a: String, _ b: String) -> Bool {
        let hay = Array(a.utf16)
        let needle = Array(b.utf16)
        if needle.isEmpty { return true }
        if needle.count > hay.count { return false }
        var i = 0
        while i + needle.count <= hay.count {
            if hay[i] == needle[0] {
                var j = 1
                while j < needle.count && hay[i + j] == needle[j] { j += 1 }
                if j == needle.count { return true }
            }
            i += 1
        }
        return false
    }

    /// Dart `s.length` (UTF-16 code units).
    package static func utf16Length(_ s: String) -> Int {
        s.utf16.count
    }
}
