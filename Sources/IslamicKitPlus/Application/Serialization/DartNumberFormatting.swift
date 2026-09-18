/// Reproduces Dart's `double.toString()` so that formatted hours and JSON
/// numbers match the Dart package byte for byte.
///
/// Dart (like JavaScript) prints the shortest round-trip digits, switching to
/// exponential notation only below `1e-6` or at/above `1e21`, and always
/// appends `.0` to integral values. Swift's `description` uses the same
/// shortest digits but different thresholds (`1e-05`, `1e+16`), so the digits
/// are taken from Swift and re-laid-out under Dart's rules.
public enum DartNumberFormatting {
    /// Dart `'$value'` / `value.toString()`.
    public static func string(_ value: Double) -> String {
        if value.isNaN { return "NaN" }
        if value.isInfinite { return value < 0 ? "-Infinity" : "Infinity" }
        if value == 0 { return value.sign == .minus ? "-0.0" : "0.0" }

        let negative = value < 0
        let (digits, pointPosition) = shortestDigits(Swift.abs(value))
        let body = layout(digits: digits, pointPosition: pointPosition)
        return negative ? "-" + body : body
    }

    /// The shortest round-trip decimal digits of a positive finite double and
    /// the position of the decimal point relative to the first digit
    /// (`value = 0.d1d2… × 10^pointPosition`).
    static func shortestDigits(_ value: Double) -> (digits: [UInt8], pointPosition: Int) {
        let text = "\(value)" // Swift: shortest round-trip, e.g. "1e-05", "13.0", "3.95"
        var mantissa = Substring(text)
        var exponent = 0
        if let e = text.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            mantissa = text[text.startIndex..<e]
            exponent = Int(text[text.index(after: e)...])!
        }
        var intPart = mantissa
        var fracPart = Substring("")
        if let dot = mantissa.firstIndex(of: ".") {
            intPart = mantissa[mantissa.startIndex..<dot]
            fracPart = mantissa[mantissa.index(after: dot)...]
        }
        var digits = [UInt8]()
        for c in intPart { digits.append(UInt8(c.asciiValue! - 48)) }
        for c in fracPart { digits.append(UInt8(c.asciiValue! - 48)) }
        var point = intPart.count + exponent
        // Strip leading zeros (moves the point left) and trailing zeros.
        while let first = digits.first, first == 0, digits.count > 1 {
            digits.removeFirst()
            point -= 1
        }
        while let last = digits.last, last == 0, digits.count > 1 {
            digits.removeLast()
        }
        return (digits, point)
    }

    /// Lays digits out under Dart's `toString` rules.
    static func layout(digits: [UInt8], pointPosition n: Int) -> String {
        let k = digits.count
        let s = digits.map { String($0) }.joined()
        if k <= n && n <= 21 {
            // Integral value: digits, n-k zeros, ".0".
            return s + String(repeating: "0", count: n - k) + ".0"
        }
        if 0 < n && n <= 21 {
            let idx = s.index(s.startIndex, offsetBy: n)
            return String(s[..<idx]) + "." + String(s[idx...])
        }
        if -6 < n && n <= 0 {
            return "0." + String(repeating: "0", count: -n) + s
        }
        let e = n - 1
        let sign = e < 0 ? "-" : "+"
        let mantissa = k == 1 ? s : String(s.first!) + "." + String(s.dropFirst())
        return mantissa + "e" + sign + String(Swift.abs(e))
    }
}
