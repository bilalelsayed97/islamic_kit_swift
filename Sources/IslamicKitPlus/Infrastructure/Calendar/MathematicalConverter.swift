/// Pure arithmetic (tabular) Hijri calendar. No validity restrictions; supports
/// a whole-day `adjustment` in both directions. Faithful port of the PHP
/// `Mathematical\Calculator`. Month length is always reported as 30 (the
/// algorithm does not track true month lengths).
public struct MathematicalConverter: HijriConverter {
    public init() {}

    public var method: CalendarMethod { .mathematical }

    public func fromGregorian(_ date: CivilDate, adjustment: Int) throws -> HijriDate {
        let jd = JulianDayMath.gregorianToJd(date.year, date.month, date.day)
        let h = JulianDayMath.mathematicalToHijri(jd, adjustment)
        return buildHijriDate(
            day: h.day,
            month: h.month,
            year: h.year,
            monthLength: 30,
            gregorianWeekday: date.isoWeekday,
            method: .mathematical
        )
    }

    public func toGregorian(year: Int, month: Int, day: Int, adjustment: Int) throws -> CivilDate {
        let jd = JulianDayMath.hijriToJd(year, month, day, adjust: adjustment)
        return JulianDayMath.jdToGregorian(jd)
    }
}
