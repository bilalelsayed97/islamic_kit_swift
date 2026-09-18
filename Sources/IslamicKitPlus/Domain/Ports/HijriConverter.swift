/// Converts between Gregorian and Hijri dates for a specific `method`.
public protocol HijriConverter: Sendable {
    var method: CalendarMethod { get }

    /// Converts a Gregorian `date` to a fully-populated `HijriDate`
    /// (localized names + holidays included).
    ///
    /// `adjustment` shifts the result by whole days (only honored by the
    /// Mathematical method; ignored by table-based methods). Throws
    /// `IslamicKitError.gregorianDateOutOfRange` outside a table's range.
    func fromGregorian(_ date: CivilDate, adjustment: Int) throws -> HijriDate

    /// Converts a Hijri date to the Gregorian civil date.
    ///
    /// `adjustment` shifts the result by whole days (only honored by the
    /// Mathematical method; ignored by table-based methods). Throws
    /// `IslamicKitError.hijriDateOutOfRange` outside a table's range.
    func toGregorian(year: Int, month: Int, day: Int, adjustment: Int) throws -> CivilDate
}

extension HijriConverter {
    /// `fromGregorian(_:adjustment:)` with no adjustment.
    public func fromGregorian(_ date: CivilDate) throws -> HijriDate {
        try fromGregorian(date, adjustment: 0)
    }

    /// `toGregorian(year:month:day:adjustment:)` with no adjustment.
    public func toGregorian(year: Int, month: Int, day: Int) throws -> CivilDate {
        try toGregorian(year: year, month: month, day: day, adjustment: 0)
    }
}
