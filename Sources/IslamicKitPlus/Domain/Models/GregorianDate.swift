/// A Gregorian calendar date with localized display fields.
public struct GregorianDate: Hashable, Sendable {
    public let day: Int
    public let month: Int
    public let year: Int

    /// English weekday name, e.g. `"Wednesday"`.
    public let weekdayEn: String

    /// English month name, e.g. `"January"`.
    public let monthEn: String

    public init(day: Int, month: Int, year: Int, weekdayEn: String, monthEn: String) {
        self.day = day
        self.month = month
        self.year = year
        self.weekdayEn = weekdayEn
        self.monthEn = monthEn
    }

    /// `dd-mm-yyyy`, matching the aladhan `gregorian.date` field.
    public var formatted: String {
        "\(StringHelpers.two(day))-\(StringHelpers.two(month))-\(StringHelpers.padLeft4(year))"
    }
}
