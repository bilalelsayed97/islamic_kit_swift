/// Hijri month number of Ramadan.
private let ramadanMonth = 9

/// Builds a complete `PrayerResult` (timings + date block + meta) for one date
/// and location. Composes the astronomy engine, the Hijri converter and the
/// localizer — the single use case the facade builds every feature on.
public struct PrayerCalculator: Sendable {
    public let astronomy: AstronomicalCalculator
    public let hijriFactory: HijriConverterFactory
    public let moonsighting: any TwilightStrategy

    public init(
        astronomy: AstronomicalCalculator = AstronomicalCalculator(),
        hijriFactory: HijriConverterFactory = HijriConverterFactory(),
        moonsighting: any TwilightStrategy = MoonsightingTwilight()
    ) {
        self.astronomy = astronomy
        self.hijriFactory = hijriFactory
        self.moonsighting = moonsighting
    }

    /// Throws `IslamicKitError.gregorianDateOutOfRange` when the selected
    /// `calendarMethod` cannot express `date` (the default HJCoSA table runs
    /// 1937-03-14 .. 2077-11-16).
    public func calculate(
        _ date: CivilDate,
        _ coordinates: Coordinates,
        _ params: CalculationParameters
    ) throws -> PrayerResult {
        let twilight: (any TwilightStrategy)? = params.method.usesMoonsighting ? moonsighting : nil
        let raw = try astronomy.compute(
            date,
            coordinates,
            params,
            twilight: twilight,
            ramadan: try isRamadan(date, params)
        )

        return PrayerResult(
            timings: PrayerTimings(raw: raw, date: date, utcOffset: params.utcOffset),
            date: try dateInfo(date, params),
            meta: meta(coordinates, params)
        )
    }

    /// Whether `date` falls in Ramadan, for methods whose Isha interval changes
    /// during the month (only Umm al-Qura does).
    ///
    /// Always resolved against the Umm al-Qura table regardless of the caller's
    /// `calendarMethod`, because the rule itself is Saudi. Dates outside the
    /// table's range fall back to the method's ordinary interval.
    private func isRamadan(_ date: CivilDate, _ params: CalculationParameters) throws -> Bool {
        if !params.effectiveParams.hasRamadanIshaInterval { return false }
        do {
            return try TableHijriConverter.ummAlQura.fromGregorian(date).month == ramadanMonth
        } catch IslamicKitError.gregorianDateOutOfRange {
            return false
        }
    }

    private func dateInfo(_ date: CivilDate, _ params: CalculationParameters) throws -> DateInfo {
        let gregorian = GregorianDate(
            day: date.day,
            month: date.month,
            year: date.year,
            weekdayEn: Localizer.gregorianWeekday(date.isoWeekday).en,
            monthEn: Localizer.gregorianMonths[date.month]!.en
        )
        let hijri = try hijriFactory.create(params.calendarMethod).fromGregorian(date)
        let readable = "\(StringHelpers.two(date.day)) \(Localizer.monthAbbrEn[date.month - 1]) \(date.year)"
        let timestamp = date.unixMidnightSeconds - params.utcOffset.seconds

        return DateInfo(readable: readable, timestamp: timestamp, gregorian: gregorian, hijri: hijri)
    }

    private func meta(_ coordinates: Coordinates, _ params: CalculationParameters) -> CalculationMeta {
        CalculationMeta(
            coordinates: coordinates,
            timezone: params.timezoneName ?? utcLabel(params.utcOffset),
            method: params.method,
            methodParams: params.effectiveParams,
            school: params.school,
            midnightMode: params.resolvedMidnightMode,
            latitudeAdjustmentMethod: params.resolvedHighLatitudeRule,
            shafaq: params.shafaq,
            offsets: params.tune.toMap()
        )
    }

    private func utcLabel(_ offset: UTCOffset) -> String {
        if offset == .zero { return "UTC" }
        return "UTC\(offset.isoString)"
    }
}
