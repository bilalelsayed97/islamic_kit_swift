/// The library's top-level facade. Offers aladhan-equivalent operations —
/// timings, next prayer, calendars (Gregorian & Hijri, by coordinates / city /
/// address), qibla and the methods list — all computed offline.
///
/// Every timings/calendar call can throw: the date block runs the Hijri
/// converter, which rejects dates outside its table (see
/// `IslamicKitError.gregorianDateOutOfRange`).
public final class PrayerTimesService: Sendable {
    /// The geocoder used by the `*ByCity` / `*ByAddress` methods.
    public let geocoder: any Geocoder

    /// The bundled city database, used by the `*ByCoordinatesAuto` methods to
    /// resolve a GPS fix to a city, its timezone and its country's recommended
    /// calculation method.
    ///
    /// Optional: without it those methods throw `IslamicKitError.directoryRequired`.
    /// `IslamicKitPlusGeocoding` provides `SqliteCityDirectory`.
    public let directory: (any CityDirectory)?

    private let calculator: PrayerCalculator
    private let qiblaCalculator: QiblaCalculator
    private let hijriFactory: HijriConverterFactory

    /// The parameters used when a call omits them (`CalculationParameters()`).
    public static let defaults = CalculationParameters()

    public init(
        geocoder: (any Geocoder)? = nil,
        directory: (any CityDirectory)? = nil,
        calculator: PrayerCalculator = PrayerCalculator(),
        qibla: QiblaCalculator = QiblaCalculator(),
        hijriFactory: HijriConverterFactory = HijriConverterFactory()
    ) {
        self.geocoder = geocoder ?? BundledCityGeocoder()
        self.directory = directory
        self.calculator = calculator
        self.qiblaCalculator = qibla
        self.hijriFactory = hijriFactory
    }

    // MARK: Daily timings

    /// Prayer times for `date` at `coordinates`.
    public func timings(
        _ date: CivilDate,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> PrayerResult {
        try calculator.calculate(date, coordinates, params)
    }

    /// Prayer times for `date` at a city, resolved via `geocoder`.
    public func timingsByCity(
        _ city: String,
        date: CivilDate,
        country: String? = nil,
        state: String? = nil,
        params: CalculationParameters = defaults
    ) throws -> PrayerResult {
        let resolved = try requireCity(city, country: country, state: state)
        return try calculator.calculate(date, resolved.coordinates, withCity(params, resolved))
    }

    /// Prayer times for `date` at a free-text address, resolved via `geocoder`.
    public func timingsByAddress(
        _ address: String,
        date: CivilDate,
        params: CalculationParameters = defaults
    ) throws -> PrayerResult {
        let resolved = try requireCity(address)
        return try calculator.calculate(date, resolved.coordinates, withCity(params, resolved))
    }

    // MARK: Location-based defaults (automatic settings — no presets needed)

    /// Recommended `CalculationParameters` for a country, choosing the method
    /// and Asr school by common regional convention (aladhan-style). Everything
    /// else keeps its default; override any field on the returned value.
    ///
    /// ```swift
    /// let p = service.recommendedParams("EG", utcOffset: UTCOffset(hours: 2))
    /// try service.timings(date, coords, p) // Egyptian method, automatically
    /// ```
    public func recommendedParams(
        _ countryCode: String,
        utcOffset: UTCOffset = .zero,
        timezoneName: String? = nil
    ) -> CalculationParameters {
        CalculationParameters(
            method: LocationDefaults.methodForCountry(countryCode),
            school: LocationDefaults.schoolForCountry(countryCode),
            utcOffset: utcOffset,
            timezoneName: timezoneName
        )
    }

    /// Fully automatic prayer times for a city: the method and Asr school are
    /// chosen from the city's country, and the UTC offset comes from the city's
    /// stored (standard-time) offset. No `CalculationParameters` required.
    ///
    /// ```swift
    /// try service.timingsByCityAuto("Cairo", date: .today(), country: "EG")
    /// ```
    public func timingsByCityAuto(
        _ city: String,
        date: CivilDate,
        country: String? = nil,
        state: String? = nil
    ) throws -> PrayerResult {
        let resolved = try requireCity(city, country: country, state: state)
        return try calculator.calculate(date, resolved.coordinates, autoParams(resolved))
    }

    /// `CalculationParameters` resolved automatically for a geocoded `city`
    /// (method + school by country, offset from the city).
    public func autoParamsForCity(_ city: City) -> CalculationParameters { autoParams(city) }

    private func autoParams(_ city: City) -> CalculationParameters {
        CalculationParameters(
            method: LocationDefaults.methodForCountry(city.country),
            school: LocationDefaults.schoolForCountry(city.country),
            utcOffset: city.utcOffset
        )
    }

    /// `CalculationParameters` resolved automatically from a GPS fix.
    ///
    /// Requires `directory` (throws `IslamicKitError.directoryRequired`
    /// otherwise). Finds the nearest city, then takes the calculation method
    /// from that city's country (as recorded in the bundled database), the Asr
    /// school from regional convention, and the UTC offset from the city's
    /// timezone.
    ///
    /// Returns `nil` when no city can be resolved for the coordinates.
    public func autoParamsForCoordinates(_ latitude: Double, _ longitude: Double) throws -> CalculationParameters? {
        guard let city = try requireDirectory().nearestCity(latitude, longitude) else { return nil }
        return autoParamsForCityEntry(city)
    }

    /// `CalculationParameters` resolved automatically for a database `city` row.
    ///
    /// The method comes from the country's recorded preference, falling back to
    /// `LocationDefaults` when the database records none.
    public func autoParamsForCityEntry(_ city: CityEntry) -> CalculationParameters {
        let method = city.calculationMethod ?? LocationDefaults.methodForCountry(city.isoCode)
        return CalculationParameters(
            method: method,
            school: LocationDefaults.schoolForCountry(city.isoCode),
            utcOffset: city.utcOffset,
            timezoneName: city.timeZoneId
        )
    }

    /// Fully automatic prayer times for a GPS fix: nearest city, its country's
    /// method, its timezone. No `CalculationParameters` required.
    ///
    /// Requires `directory`. Returns `nil` when no city can be resolved.
    ///
    /// The stored offset is **standard time** — add an hour yourself where
    /// daylight saving is in force on `date`.
    public func timingsByCoordinatesAuto(
        _ latitude: Double,
        _ longitude: Double,
        date: CivilDate
    ) throws -> PrayerResult? {
        guard let city = try requireDirectory().nearestCity(latitude, longitude) else { return nil }
        return try calculator.calculate(date, city.coordinates, autoParamsForCityEntry(city))
    }

    private func requireDirectory() throws -> any CityDirectory {
        guard let open = directory else { throw IslamicKitError.directoryRequired }
        return open
    }

    // MARK: Next prayer

    /// The next obligatory prayer strictly after `from` (wall-clock local time,
    /// interpreted with `params.utcOffset`). Rolls to the next day's Fajr if
    /// `from` is after Isha.
    public func nextPrayer(
        _ from: CivilDateTime,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> NextPrayer {
        let localHour = from.fractionalHours
        let today = try calculator.calculate(from.date, coordinates, params)
        for prayer in Prayer.dailyObligatory {
            if let h = today.timings.raw[prayer], !h.isNaN, h > localHour {
                return NextPrayer(prayer: prayer, time: today.timings.time(prayer), onDate: today.timings.date)
            }
        }
        let tomorrow = from.date.addingDays(1)
        let next = try calculator.calculate(tomorrow, coordinates, params)
        return NextPrayer(prayer: .fajr, time: next.timings.time(.fajr), onDate: tomorrow)
    }

    /// `nextPrayer` resolved via `geocoder` for a free-text address.
    public func nextPrayerByAddress(
        _ address: String,
        _ from: CivilDateTime,
        _ params: CalculationParameters = defaults
    ) throws -> NextPrayer {
        let resolved = try requireCity(address)
        return try nextPrayer(from, resolved.coordinates, withCity(params, resolved))
    }

    // MARK: Qibla & methods

    /// The Qibla direction from `from` (degrees clockwise from true north).
    public func qibla(_ from: Coordinates) -> QiblaDirection { qiblaCalculator.direction(from) }

    /// All available calculation methods, in declaration order.
    public func methods() -> [CalculationMethod] { CalculationMethod.allCases }

    // MARK: Calendars — Gregorian

    /// Every day of a Gregorian month.
    public func monthlyCalendar(
        _ year: Int,
        _ month: Int,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> [PrayerResult] {
        let days = daysInGregorianMonth(year, month)
        return try (1...days).map { d in
            try calculator.calculate(CivilDate(year: year, month: month, day: d), coordinates, params)
        }
    }

    /// Every day of a Gregorian year, keyed by month 1..12.
    public func annualCalendar(
        _ year: Int,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> [Int: [PrayerResult]] {
        var out = [Int: [PrayerResult]]()
        for m in 1...12 {
            out[m] = try monthlyCalendar(year, m, coordinates, params)
        }
        return out
    }

    /// Every day between `start` and `end` inclusive (max 11 months apart).
    public func rangeCalendar(
        _ start: CivilDate,
        _ end: CivilDate,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> [PrayerResult] {
        if end < start {
            throw IslamicKitError.invalidDateRange("end must be on or after start.")
        }
        let maxEnd = CivilDate(year: start.year, month: start.month + 11, day: start.day)
        if end > maxEnd {
            throw IslamicKitError.invalidDateRange("Date range must be at most 11 months.")
        }
        var out = [PrayerResult]()
        var d = start
        while d <= end {
            out.append(try calculator.calculate(d, coordinates, params))
            d = d.addingDays(1)
        }
        return out
    }

    /// `monthlyCalendar` for a city.
    public func monthlyCalendarByCity(
        _ year: Int,
        _ month: Int,
        _ city: String,
        country: String? = nil,
        state: String? = nil,
        params: CalculationParameters = defaults
    ) throws -> [PrayerResult] {
        let resolved = try requireCity(city, country: country, state: state)
        return try monthlyCalendar(year, month, resolved.coordinates, withCity(params, resolved))
    }

    // MARK: Calendars — Hijri

    /// Every day of a Hijri month.
    public func monthlyHijriCalendar(
        _ hijriYear: Int,
        _ hijriMonth: Int,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> [PrayerResult] {
        let converter = hijriFactory.create(params.calendarMethod)
        let start = try converter.toGregorian(year: hijriYear, month: hijriMonth, day: 1)
        let length = try converter.fromGregorian(start).monthLength
        return try (0..<length).map { i in
            try calculator.calculate(start.addingDays(i), coordinates, params)
        }
    }

    /// Every day of a Hijri year, keyed by Hijri month 1..12.
    public func annualHijriCalendar(
        _ hijriYear: Int,
        _ coordinates: Coordinates,
        _ params: CalculationParameters = defaults
    ) throws -> [Int: [PrayerResult]] {
        var out = [Int: [PrayerResult]]()
        for m in 1...12 {
            out[m] = try monthlyHijriCalendar(hijriYear, m, coordinates, params)
        }
        return out
    }

    /// `monthlyHijriCalendar` for a city.
    public func monthlyHijriCalendarByCity(
        _ hijriYear: Int,
        _ hijriMonth: Int,
        _ city: String,
        country: String? = nil,
        state: String? = nil,
        params: CalculationParameters = defaults
    ) throws -> [PrayerResult] {
        let resolved = try requireCity(city, country: country, state: state)
        return try monthlyHijriCalendar(hijriYear, hijriMonth, resolved.coordinates, withCity(params, resolved))
    }

    // MARK: Helpers

    private func requireCity(_ query: String, country: String? = nil, state: String? = nil) throws -> City {
        guard let city = geocoder.resolve(query, country: country, state: state) else {
            throw IslamicKitError.locationNotFound(query: query)
        }
        return city
    }

    /// Applies the city's standard UTC offset unless the caller set one already.
    private func withCity(_ params: CalculationParameters, _ city: City) -> CalculationParameters {
        params.utcOffset == .zero ? params.with { $0.utcOffset = city.utcOffset } : params
    }

    private func daysInGregorianMonth(_ year: Int, _ month: Int) -> Int {
        CivilDate(year: year, month: month + 1, day: 0).day
    }
}
