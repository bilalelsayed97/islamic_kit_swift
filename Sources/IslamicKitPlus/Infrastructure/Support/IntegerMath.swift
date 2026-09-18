/// Integer helpers that reproduce Dart's arithmetic semantics.
///
/// Dart's `~/` truncates toward zero (Swift `/` does the same), but Dart's
/// `.floor()` on a quotient and `int % int` with a positive divisor are
/// floor-based, which Swift's `/` and `%` are not for negative operands.
package enum IntegerMath {
    /// Floor division: the largest integer not greater than `a / b`.
    package static func floorDiv(_ a: Int, _ b: Int) -> Int {
        let q = a / b
        return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q
    }

    /// Floor modulo: the result has the sign of `b` (non-negative for `b > 0`),
    /// matching Dart's `int % int`.
    package static func floorMod(_ a: Int, _ b: Int) -> Int {
        let r = a % b
        return (r != 0 && (r < 0) != (b < 0)) ? r + b : r
    }

    /// Rounds half **up**, i.e. `floor(x + 0.5)`.
    ///
    /// Swift's `rounded()` rounds half *away from zero*, which disagrees on
    /// exact negative halves (`-0.5` → `0` here, `-1` there).
    package static func javaRound(_ x: Double) -> Int {
        Int((x + 0.5).rounded(.down))
    }
}
