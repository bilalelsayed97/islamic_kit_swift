/// High Judiciary Council of Saudi Arabia: the Umm al-Qura table overlaid with
/// announced lunar-sighting adjustments (both directions). Faithful port of the
/// PHP `HighJudiciaryCouncilOfSaudiArabia` class.
public struct HjcosaConverter: HijriConverter {
    private static let uaq = TableHijriConverter(
        method: .hjcosa,
        data: UmmAlQuraTable.data,
        lunations: 16260,
        gregorianFrom: YMD(1937, 3, 14),
        gregorianTo: YMD(2077, 11, 16),
        hijriFrom: YMD(1356, 1, 1),
        hijriTo: YMD(1500, 12, 30)
    )

    public init() {}

    public var method: CalendarMethod { .hjcosa }

    public func fromGregorian(_ date: CivilDate, adjustment: Int) throws -> HijriDate {
        try HjcosaConverter.uaq.verifyGregorian(date)
        let key = "\(StringHelpers.two(date.day))-\(StringHelpers.two(date.month))-\(date.year)"
        guard let announced = HijriSightings.gregorianToHijri[key] else {
            return try HjcosaConverter.uaq.fromGregorian(date)
        }

        let parts = announced.split(separator: "-")
        let d = Int(parts[0])!
        let m = Int(parts[1])!
        let y = Int(parts[2])!

        // Month length from a reference calc on the 7th of the announced month,
        // since sightings adjust the *start* of a month.
        let refJd = JulianDayMath.hijriToJd(y, m, 7)
        let ref = JulianDayMath.tableToHijri(UmmAlQuraTable.data, 16260, refJd)

        return buildHijriDate(
            day: d,
            month: m,
            year: y,
            monthLength: ref.monthLength,
            gregorianWeekday: date.isoWeekday,
            method: .hjcosa
        )
    }

    public func toGregorian(year: Int, month: Int, day: Int, adjustment: Int) throws -> CivilDate {
        try HjcosaConverter.uaq.verifyHijri(year: year, month: month, day: day)
        let key = "\(StringHelpers.two(day))-\(StringHelpers.two(month))-\(year)"
        if let gregorian = HijriSightings.hijriToGregorian[key] {
            let p = gregorian.split(separator: "-")
            return CivilDate(year: Int(p[2])!, month: Int(p[1])!, day: Int(p[0])!)
        }
        let jd = JulianDayMath.hijriToJd(year, month, day, adjust: adjustment)
        return JulianDayMath.jdToGregorian(jd)
    }
}
