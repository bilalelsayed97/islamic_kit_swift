import Foundation

/// A proleptic-Gregorian calendar date with no time zone attached — the port
/// of the date-only `DateTime` values the Dart package passes around.
///
/// Arithmetic is done on the Julian Day Number, so day and month overflow
/// normalise exactly like Dart's `DateTime(year, month, day)` constructor
/// (`CivilDate(year: 2014, month: 2, day: 30)` is 2014-03-02 and a `day` of
/// `0` is the last day of the previous month) without any host time zone or
/// DST leaking in.
public struct CivilDate: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Creates a date, normalising month and day overflow (month first, then
    /// day) exactly as Dart's `DateTime` does.
    public init(year: Int, month: Int, day: Int) {
        let m0 = month - 1
        let y = year + IntegerMath.floorDiv(m0, 12)
        let m = IntegerMath.floorMod(m0, 12) + 1
        let jdn = CivilDate.julianDayNumber(year: y, month: m, day: 1) + (day - 1)
        self.init(julianDayNumber: jdn)
    }

    /// Creates a date from its Julian Day Number.
    public init(julianDayNumber jdn: Int) {
        let a = jdn + 32044
        let b = IntegerMath.floorDiv(4 * a + 3, 146097)
        let c = a - IntegerMath.floorDiv(146097 * b, 4)
        let d = IntegerMath.floorDiv(4 * c + 3, 1461)
        let e = c - IntegerMath.floorDiv(1461 * d, 4)
        let m = IntegerMath.floorDiv(5 * e + 2, 153)
        self.day = e - IntegerMath.floorDiv(153 * m + 2, 5) + 1
        self.month = m + 3 - 12 * IntegerMath.floorDiv(m, 10)
        self.year = 100 * b + d - 4800 + IntegerMath.floorDiv(m, 10)
    }

    /// The Julian Day Number of a proleptic-Gregorian date (no normalisation).
    static func julianDayNumber(year: Int, month: Int, day: Int) -> Int {
        let a = IntegerMath.floorDiv(14 - month, 12)
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        return day + IntegerMath.floorDiv(153 * m + 2, 5) + 365 * y
            + IntegerMath.floorDiv(y, 4) - IntegerMath.floorDiv(y, 100) + IntegerMath.floorDiv(y, 400)
            - 32045
    }

    /// The Julian Day Number (chronological, at noon; 2000-01-01 is 2451545).
    public var julianDayNumber: Int {
        CivilDate.julianDayNumber(year: year, month: month, day: day)
    }

    /// ISO weekday: Monday = 1 … Sunday = 7 (Dart `DateTime.weekday`).
    public var isoWeekday: Int {
        IntegerMath.floorMod(julianDayNumber, 7) + 1
    }

    /// Days since 1970-01-01.
    public var epochDay: Int { julianDayNumber - 2440588 }

    /// Seconds since the Unix epoch at 00:00 UTC of this civil date.
    public var unixMidnightSeconds: Int { epochDay * 86400 }

    /// Whether `year` is a Gregorian leap year.
    public var isLeapYear: Bool { CivilDate.isLeapYear(year) }

    public static func isLeapYear(_ year: Int) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    /// Number of days in this date's month.
    public var daysInMonth: Int { CivilDate.daysInMonth(year: year, month: month) }

    public static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2: return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// 1-based day of the year.
    public var dayOfYear: Int {
        julianDayNumber - CivilDate(year: year, month: 1, day: 1).julianDayNumber + 1
    }

    /// This date shifted by `days` (negative allowed).
    public func addingDays(_ days: Int) -> CivilDate {
        CivilDate(julianDayNumber: julianDayNumber + days)
    }

    /// This date shifted by `months`, with Dart-style day overflow
    /// (`2014-01-31` + 1 month is `2014-03-03`).
    public func addingMonths(_ months: Int) -> CivilDate {
        CivilDate(year: year, month: month + months, day: day)
    }

    /// `yyyy-mm-dd`.
    public var isoString: String {
        "\(StringHelpers.padLeft4(year))-\(StringHelpers.two(month))-\(StringHelpers.two(day))"
    }

    public var description: String { isoString }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool {
        lhs.julianDayNumber < rhs.julianDayNumber
    }

    // MARK: Foundation conveniences

    /// The civil date of `date` as seen in `timeZone`.
    public init(_ date: Date, in timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year!, month: c.month!, day: c.day!)
    }

    /// Today's civil date in `timeZone`.
    public static func today(in timeZone: TimeZone = .current) -> CivilDate {
        CivilDate(Date(), in: timeZone)
    }

    /// 00:00 UTC of this civil date as a Foundation `Date`.
    public var utcMidnight: Date {
        Date(timeIntervalSince1970: TimeInterval(unixMidnightSeconds))
    }
}
