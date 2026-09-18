/// Seconds in a day. The engine works in whole seconds from 00:00 UTC of the
/// requested civil date, which keeps every interval exact.
private let secondsPerDay = 86400

/// Computes raw prayer times (fractional local hours) for a date and location.
///
/// Values may be negative or exceed 24 when an event rolls into the adjacent
/// day; `nil` marks a time that cannot be computed (polar day or polar
/// night).
///
/// Times are rounded to the nearest minute here, so a formatted result never
/// depends on formatting-time rounding.
public struct AstronomicalCalculator: Sendable {
    public init() {}

    /// Returns raw fractional local hours for every `Prayer`.
    ///
    /// `twilight` supplies the Moonsighting Committee's seasonal bounds; it is
    /// required only when `params.method.usesMoonsighting` is set (throws
    /// `IslamicKitError.twilightStrategyRequired` otherwise).
    ///
    /// `ramadan` selects the method's Ramadan Isha interval where it defines one
    /// (Umm al-Qura lengthens 90 minutes to 120). The caller decides, because
    /// resolving the Hijri month is a calendar concern, not an astronomical one.
    public func compute(
        _ date: CivilDate,
        _ coordinates: Coordinates,
        _ params: CalculationParameters,
        twilight: (any TwilightStrategy)? = nil,
        ramadan: Bool = false
    ) throws -> RawPrayerTimes {
        try Computation(date: date, coordinates: coordinates, params: params, twilight: twilight, ramadan: ramadan).run()
    }
}

private struct Computation {
    let date: CivilDate
    let coordinates: Coordinates
    let params: CalculationParameters
    let twilight: (any TwilightStrategy)?
    let ramadan: Bool
    let mp: MethodParams

    init(
        date: CivilDate,
        coordinates: Coordinates,
        params: CalculationParameters,
        twilight: (any TwilightStrategy)?,
        ramadan: Bool
    ) {
        self.date = date
        self.coordinates = coordinates
        self.params = params
        self.twilight = twilight
        self.ramadan = ramadan
        self.mp = ramadan ? params.effectiveParams.forRamadan() : params.effectiveParams
    }

    var latitude: Double { coordinates.latitude }

    func run() throws -> RawPrayerTimes {
        let solar = SolarTime(date: date, coordinates: coordinates, elevation: params.elevation)

        let transitOpt = seconds(solar.transit)
        let sunriseOpt = seconds(solar.sunrise)
        let sunsetOpt = seconds(solar.sunset)
        let asrOpt = seconds(solar.afternoon(params.resolvedShadowFactor))

        // Polar day or polar night: the sun never crosses the horizon, so no time
        // can be anchored and the whole day is invalid.
        guard let transit = transitOpt, let sunrise = sunriseOpt, let sunset = sunsetOpt, let asr = asrOpt else {
            return .allInvalid
        }

        let night = (sunrise + secondsPerDay) - sunset
        let fajr = try self.fajr(solar, sunrise: sunrise, night: night)
        let maghrib = maghribBase(solar, sunset: sunset)
        let isha = try self.isha(solar, sunset: sunset, maghrib: maghrib, night: night)

        let imsak = fajr.map { $0 - params.imsakMinutes * 60 }
        let dhuhr = transit + params.dhuhrMinutes * 60

        let adjustments = mp.adjustments
        var result = [Prayer: Int?]()
        result[.imsak] = imsak
        result[.fajr] = shift(fajr, adjustments.fajr)
        result[.sunrise] = shift(sunrise, adjustments.sunrise)
        result[.dhuhr] = shift(dhuhr, adjustments.dhuhr)
        result[.asr] = shift(asr, adjustments.asr)
        result[.sunset] = sunset
        result[.maghrib] = shift(maghrib, adjustments.maghrib)
        result[.isha] = shift(isha, adjustments.isha)

        // Midnight and the night thirds are derived from the *unadjusted* anchors.
        for (prayer, value) in nightTimes(sunset: sunset, sunrise: sunrise, fajr: fajr) {
            result[prayer] = value
        }

        return finalize(result)
    }

    // MARK: Individual times

    /// Fajr, floored by the high-latitude safe bound.
    func fajr(_ solar: SolarTime, sunrise: Int, night: Int) throws -> Int? {
        var candidate = seconds(solar.hourAngle(-mp.fajrAngle, afterTransit: false))

        // Above 55°N the Moonsighting method abandons the angle entirely.
        if usesMoonsighting && latitude >= 55 {
            candidate = sunrise - night / 7
        }

        let rule = params.resolvedHighLatitudeRule
        if rule == .none { return candidate }

        let safe = usesMoonsighting
            ? sunrise - (try requireTwilight().fajrSecondsBeforeSunrise(date, latitude: latitude))
            : sunrise - Int(Double(night) * nightPortion(rule, mp.fajrAngle))

        guard let c = candidate, c >= safe else { return safe }
        return c
    }

    /// The Maghrib anchor: sunset, or the method's own interval/angle.
    func maghribBase(_ solar: SolarTime, sunset: Int) -> Int {
        if let minutes = mp.maghribMinutesAfterSunset { return sunset + minutes * 60 }

        if let angle = mp.maghribAngle {
            if let byAngle = seconds(solar.hourAngle(-angle, afterTransit: true)) { return byAngle }
        }
        return sunset
    }

    /// Isha, capped by the high-latitude safe bound when angle-based.
    func isha(_ solar: SolarTime, sunset: Int, maghrib: Int, night: Int) throws -> Int? {
        // A fixed interval is definitional: no high-latitude bound applies.
        if let interval = mp.ishaMinutesAfterMaghrib { return maghrib + interval * 60 }

        let ishaAngle = mp.ishaAngle ?? 0
        var candidate = seconds(solar.hourAngle(-ishaAngle, afterTransit: true))

        if usesMoonsighting && latitude >= 55 {
            candidate = sunset + night / 7
        }

        let rule = params.resolvedHighLatitudeRule
        if rule == .none { return candidate }

        let safe = usesMoonsighting
            ? sunset + (try requireTwilight().ishaSecondsAfterSunset(date, latitude: latitude, shafaq: params.shafaq))
            : sunset + Int(Double(night) * nightPortion(rule, ishaAngle))

        if let c = candidate, c <= safe { return c }
        return safe
    }

    /// Midnight and the night thirds.
    ///
    /// The night runs from sunset to the following Fajr (`.jafari`, the
    /// default) or to the following sunrise (`.standard`).
    func nightTimes(sunset: Int, sunrise: Int, fajr: Int?) -> [(Prayer, Int?)] {
        let anchor = params.resolvedMidnightMode == .standard ? sunrise : fajr
        guard let anchor = anchor else {
            return [(.midnight, nil), (.firstThird, nil), (.lastThird, nil)]
        }

        let night = (anchor + secondsPerDay) - sunset
        return [
            (.midnight, sunset + night / 2),
            (.firstThird, sunset + night / 3),
            (.lastThird, sunset + (night * 2) / 3),
        ]
    }

    // MARK: Helpers

    var usesMoonsighting: Bool { params.method.usesMoonsighting }

    /// The Moonsighting strategy. Only read when the method needs it, so a
    /// caller that never selects Moonsighting need not supply one.
    func requireTwilight() throws -> any TwilightStrategy {
        guard let strategy = twilight else {
            throw IslamicKitError.twilightStrategyRequired(method: params.method.code)
        }
        return strategy
    }

    /// The fraction of the night that bounds a twilight time under `rule`.
    func nightPortion(_ rule: HighLatitudeRule, _ angle: Double) -> Double {
        switch rule {
        case .angleBased: return angle / 60.0
        case .oneSeventh: return 1.0 / 7
        case .middleOfNight, .none: return 1.0 / 2
        }
    }

    /// Truncates fractional UTC hours to whole seconds, or `nil` when the value
    /// is not a real time (the sun never reached the requested angle).
    func seconds(_ hours: Double) -> Int? {
        if hours.isNaN || hours.isInfinite { return nil }
        return Int((hours * 3600).rounded(.down))
    }

    func shift(_ seconds: Int?, _ minutes: Int) -> Int? {
        seconds.map { $0 + minutes * 60 }
    }

    /// Applies user tuning, rounds to the nearest minute and converts to
    /// fractional local hours.
    func finalize(_ times: [Prayer: Int?]) -> RawPrayerTimes {
        let tune = params.tune.toMap()
        let offsetSeconds = params.utcOffset.seconds

        return RawPrayerTimes { prayer in
            toLocalHours(times[prayer] ?? nil, tune[prayer] ?? 0, offsetSeconds)
        }
    }

    func toLocalHours(_ seconds: Int?, _ tuneMinutes: Int, _ offsetSeconds: Int) -> Double? {
        guard let seconds = seconds else { return nil }
        let tuned = seconds + tuneMinutes * 60
        // Round to the nearest minute: seconds >= 30 advance the minute.
        let minutes = IntegerMath.floorDiv(tuned, 60) + (IntegerMath.floorMod(tuned, 60) >= 30 ? 1 : 0)
        return Double(minutes * 60 + offsetSeconds) / 3600.0
    }
}
