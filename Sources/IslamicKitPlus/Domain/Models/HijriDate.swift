/// A Hijri (Islamic) calendar date with localized display fields and holidays.
public struct HijriDate: Hashable, Sendable {
    public let day: Int

    /// Month number 1..12 (1 = Muharram).
    public let month: Int
    public let year: Int

    /// English weekday name, e.g. `"Friday"`.
    public let weekdayEn: String

    /// Arabic weekday name, e.g. `"الجمعة"`.
    public let weekdayAr: String

    /// English (transliterated) month name, e.g. `"Rajab"`.
    public let monthEn: String

    /// Arabic month name, e.g. `"رَجَب"`.
    public let monthAr: String

    /// Number of days in this Hijri month (29 or 30).
    public let monthLength: Int

    /// The calendar method used to compute this date.
    public let method: CalendarMethod

    /// Islamic holidays/observances on this Hijri day (may be empty).
    public let holidays: [String]

    public init(
        day: Int,
        month: Int,
        year: Int,
        weekdayEn: String,
        weekdayAr: String,
        monthEn: String,
        monthAr: String,
        monthLength: Int,
        method: CalendarMethod,
        holidays: [String] = []
    ) {
        self.day = day
        self.month = month
        self.year = year
        self.weekdayEn = weekdayEn
        self.weekdayAr = weekdayAr
        self.monthEn = monthEn
        self.monthAr = monthAr
        self.monthLength = monthLength
        self.method = method
        self.holidays = holidays
    }

    /// `dd-mm-yyyy`, matching the aladhan `hijri.date` field.
    public var formatted: String {
        "\(StringHelpers.two(day))-\(StringHelpers.two(month))-\(StringHelpers.padLeft4(year))"
    }
}
