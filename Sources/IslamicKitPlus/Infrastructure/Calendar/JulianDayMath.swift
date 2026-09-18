/// Low-level Julian-Day math for Hijri <-> Gregorian conversion.
///
/// Julian-day conversions for the Gregorian and Hijri calendars,
/// `Date/Julian` and `Date/Hijri`. All values are chronological Julian Day
/// numbers (CJDN); integer/truncating arithmetic is used exactly as in the PHP.
public enum JulianDayMath {
    /// Numeric parts of a Hijri date (plus the month length where a table
    /// supplies one).
    public struct HijriParts: Hashable, Sendable {
        public let year: Int
        public let month: Int
        public let day: Int
        public let monthLength: Int
    }

    /// Truncation with the PHP `intPart` epsilon (±1e-7).
    public static func intPart(_ x: Double) -> Double {
        x < -0.0000001 ? (x - 0.0000001).rounded(.up) : (x + 0.0000001).rounded(.down)
    }

    /// Gregorian date -> CJDN.
    ///
    /// Note: the century offset uses the *original* year (matching the PHP,
    /// which reads the century from the unadjusted date even for Jan/Feb).
    public static func gregorianToJd(_ year: Int, _ month: Int, _ day: Int) -> Int {
        var y = year
        var m = month
        let a = IntegerMath.floorDiv(year, 100)
        if m < 3 {
            y -= 1
            m += 12
        }
        let jgc = a - IntegerMath.floorDiv(a, 4) - 2
        return Int((365.25 * Double(y + 4716)).rounded(.down))
            + Int((30.6001 * Double(m + 1)).rounded(.down))
            + day
            - jgc
            - 1524
    }

    /// CJDN -> Gregorian date.
    public static func jdToGregorian(_ jd: Int) -> CivilDate {
        let a = Int(((Double(jd) - 1867216.25) / 36524.25).rounded(.down))
        let jgc = a - IntegerMath.floorDiv(a, 4) + 1
        let b = jd + jgc + 1524
        let c = Int(((Double(b) - 122.1) / 365.25).rounded(.down))
        let d = Int((365.25 * Double(c)).rounded(.down))
        var month = Int((Double(b - d) / 30.6001).rounded(.down))
        let day = (b - d) - Int((30.6001 * Double(month)).rounded(.down))
        var cc = c
        if month > 13 {
            cc += 1
            month -= 12
        }
        month -= 1
        return CivilDate(year: cc - 4716, month: month, day: day)
    }

    /// Hijri date -> CJDN (pure arithmetic, used by every `hToG`).
    public static func hijriToJd(_ year: Int, _ month: Int, _ day: Int, adjust: Int = 0) -> Int {
        ((11 * year + 3) / 30)
            + 354 * year
            + 30 * month
            - ((month - 1) / 2)
            + day
            + 1948440
            - 385
            + adjust
    }

    /// CJDN -> Hijri via a lunation-start table lookup (Umm al-Qura / Diyanet).
    public static func tableToHijri(_ data: [Int], _ lunations: Int, _ jd: Int) -> HijriParts {
        let mcjdn = jd - 2400000
        var i = 0
        while i < data.count {
            if data[i] > mcjdn { break }
            i += 1
        }
        let iln = i + lunations
        let ii = IntegerMath.floorDiv(iln - 1, 12)
        return HijriParts(
            year: ii + 1,
            month: iln - 12 * ii,
            day: mcjdn - data[i - 1] + 1,
            monthLength: data[i] - data[i - 1]
        )
    }

    /// CJDN -> Hijri via the pure arithmetic (tabular) algorithm.
    public static func mathematicalToHijri(_ jd: Int, _ adjustment: Int) -> HijriParts {
        var l = Double(jd + adjustment - 1948440) + 10632.0
        let n = intPart((l - 1) / 10631)
        l = l - 10631 * n + 354
        let j = intPart((10985 - l) / 5316) * intPart((50 * l) / 17719)
            + intPart(l / 5670) * intPart((43 * l) / 15238)
        l = l
            - intPart((30 - j) / 15) * intPart((17719 * j) / 50)
            - intPart(j / 16) * intPart((15238 * j) / 43)
            + 29
        let m = intPart((24 * l) / 709)
        let d = l - intPart((709 * m) / 24)
        let y = 30 * n + j - 30
        return HijriParts(year: Int(y), month: Int(m), day: Int(d), monthLength: 30)
    }
}
