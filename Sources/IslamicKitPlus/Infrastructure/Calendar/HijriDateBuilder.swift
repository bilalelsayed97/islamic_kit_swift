/// Assembles a fully-populated `HijriDate` from raw numeric parts, filling in
/// localized month/weekday names (from `Localizer`) and holidays. The weekday
/// is derived from the corresponding Gregorian date's ISO weekday.
public func buildHijriDate(
    day: Int,
    month: Int,
    year: Int,
    monthLength: Int,
    gregorianWeekday: Int,
    method: CalendarMethod
) -> HijriDate {
    let m = Localizer.islamicMonths[month]!
    let wd = Localizer.hijriWeekday(gregorianWeekday)
    let holidays = HijriHolidays.byMonth[month]?[day] ?? []
    return HijriDate(
        day: day,
        month: month,
        year: year,
        weekdayEn: wd.en,
        weekdayAr: wd.ar,
        monthEn: m.en,
        monthAr: m.ar,
        monthLength: monthLength,
        method: method,
        holidays: holidays
    )
}
