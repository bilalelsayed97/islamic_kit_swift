/// A `(year, month, day)` triple used for table validity bounds. Hijri bounds
/// such as 1500-12-30 are not valid `CivilDate`s, so this stays numeric.
struct YMD: Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    var encoded: Int { year * 10000 + month * 100 + day }

    /// Dart's record `toString()`: `(1937, 3, 14)`.
    var dartDescription: String { "(\(year), \(month), \(day))" }
}

/// Table-driven converter (Umm al-Qura, Diyanet). Both directions read the same
/// lunation table, so they are exact inverses: `toGregorian(fromGregorian(d))`
/// is `d` for every date in range.
///
/// (The PHP original converts Hijri -> Gregorian with the arithmetic calendar
/// instead, which lands a day or two off whenever the observed month start
/// differs from the tabular one. That is a defect, not a convention, and is
/// not reproduced here.)
public struct TableHijriConverter: HijriConverter {
    public let method: CalendarMethod
    let data: [Int]
    let lunations: Int
    let gregorianFrom: YMD
    let gregorianTo: YMD
    let hijriFrom: YMD
    let hijriTo: YMD

    init(
        method: CalendarMethod,
        data: [Int],
        lunations: Int,
        gregorianFrom: YMD,
        gregorianTo: YMD,
        hijriFrom: YMD,
        hijriTo: YMD
    ) {
        self.method = method
        self.data = data
        self.lunations = lunations
        self.gregorianFrom = gregorianFrom
        self.gregorianTo = gregorianTo
        self.hijriFrom = hijriFrom
        self.hijriTo = hijriTo
    }

    /// Umm al-Qura configuration (valid 1356–1500 AH).
    public static let ummAlQura = TableHijriConverter(
        method: .uaq,
        data: UmmAlQuraTable.data,
        lunations: 16260,
        gregorianFrom: YMD(1937, 3, 14),
        gregorianTo: YMD(2077, 11, 16),
        hijriFrom: YMD(1356, 1, 1),
        hijriTo: YMD(1500, 12, 30)
    )

    /// Diyanet configuration (valid 1318–1449 AH).
    public static let diyanet = TableHijriConverter(
        method: .diyanet,
        data: DiyanetTable.data,
        lunations: 15804,
        gregorianFrom: YMD(1900, 5, 1),
        gregorianTo: YMD(2028, 1, 26),
        hijriFrom: YMD(1318, 1, 1),
        hijriTo: YMD(1449, 8, 29)
    )

    /// Throws `IslamicKitError.gregorianDateOutOfRange` outside the table.
    public func verifyGregorian(_ date: CivilDate) throws {
        let v = YMD(date.year, date.month, date.day).encoded
        if v < gregorianFrom.encoded || v > gregorianTo.encoded {
            throw IslamicKitError.gregorianDateOutOfRange(
                "Gregorian date out of range for \(method.code) "
                    + "(\(gregorianFrom.dartDescription) .. \(gregorianTo.dartDescription))."
            )
        }
    }

    /// Throws `IslamicKitError.hijriDateOutOfRange` outside the table.
    public func verifyHijri(year: Int, month: Int, day: Int) throws {
        let v = YMD(year, month, day).encoded
        if v < hijriFrom.encoded || v > hijriTo.encoded {
            throw hijriOutOfRange
        }
    }

    public func fromGregorian(_ date: CivilDate, adjustment: Int) throws -> HijriDate {
        try verifyGregorian(date)
        let jd = JulianDayMath.gregorianToJd(date.year, date.month, date.day)
        let h = JulianDayMath.tableToHijri(data, lunations, jd)
        return buildHijriDate(
            day: h.day,
            month: h.month,
            year: h.year,
            monthLength: h.monthLength,
            gregorianWeekday: date.isoWeekday,
            method: method
        )
    }

    private var hijriOutOfRange: IslamicKitError {
        .hijriDateOutOfRange(
            "Hijri date out of range for \(method.code) "
                + "(\(hijriFrom.dartDescription) .. \(hijriTo.dartDescription))."
        )
    }

    /// The table lookup run backwards. `adjustment` shifts the result by whole
    /// days (it has no effect on `fromGregorian`, as in the original).
    public func toGregorian(year: Int, month: Int, day: Int, adjustment: Int) throws -> CivilDate {
        try verifyHijri(year: year, month: month, day: day)
        // A month number outside 1...12 can pass the bounds check above yet
        // point past the table.
        guard let jd = JulianDayMath.tableToJd(data, lunations, year, month, day) else {
            throw hijriOutOfRange
        }
        return JulianDayMath.jdToGregorian(jd + adjustment)
    }
}
