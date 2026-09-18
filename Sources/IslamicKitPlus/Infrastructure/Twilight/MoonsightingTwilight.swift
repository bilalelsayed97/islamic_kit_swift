/// Moonsighting Committee Worldwide Fajr/Isha twilight.
///
/// A piecewise-linear interpolation of "minutes from sunrise/sunset" driven by
/// the day count since the winter (northern) or summer (southern) solstice,
/// with per-latitude coefficients, as published by the committee.
public struct MoonsightingTwilight: TwilightStrategy {
    public init() {}

    public func fajrSecondsBeforeSunrise(_ date: CivilDate, latitude: Double) -> Int {
        let absLat = Swift.abs(latitude)
        let minutes = interpolate(
            daysSinceSolstice(date, latitude),
            75 + 28.65 / 55.0 * absLat,
            75 + 19.44 / 55.0 * absLat,
            75 + 32.74 / 55.0 * absLat,
            75 + 48.10 / 55.0 * absLat
        )
        return Astronomical.javaRound(minutes * 60.0)
    }

    public func ishaSecondsAfterSunset(_ date: CivilDate, latitude: Double, shafaq: Shafaq) -> Int {
        let absLat = Swift.abs(latitude)
        let c = ishaCoefficients(shafaq, absLat)
        let minutes = interpolate(daysSinceSolstice(date, latitude), c[0], c[1], c[2], c[3])
        return Astronomical.javaRound(minutes * 60.0)
    }

    /// Whole days since the hemisphere's solstice, wrapped into the year.
    ///
    /// Derived from the day-of-year rather than a date subtraction so that leap
    /// years and the New Year boundary land on the published day.
    private func daysSinceSolstice(_ date: CivilDate, _ latitude: Double) -> Int {
        let leap = date.isLeapYear
        let daysInYear = leap ? 366 : 365
        let dayOfYear = date.dayOfYear

        if latitude >= 0 {
            // The December solstice sits 10 days before year-end.
            let days = dayOfYear + 10
            return days >= daysInYear ? days - daysInYear : days
        }
        let southernOffset = leap ? 173 : 172
        let days = dayOfYear - southernOffset
        return days < 0 ? days + daysInYear : days
    }

    private func interpolate(_ dyy: Int, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
        let x = Double(dyy)
        if dyy < 91 { return a + (b - a) / 91 * x }
        if dyy < 137 { return b + (c - b) / 46 * (x - 91) }
        if dyy < 183 { return c + (d - c) / 46 * (x - 137) }
        if dyy < 229 { return d + (c - d) / 46 * (x - 183) }
        if dyy < 275 { return c + (b - c) / 46 * (x - 229) }
        return b + (a - b) / 91 * (x - 275)
    }

    /// Returns the `[a, b, c, d]` seasonal coefficients for `shafaq`.
    private func ishaCoefficients(_ shafaq: Shafaq, _ absLat: Double) -> [Double] {
        switch shafaq {
        case .ahmer:
            return [
                62 + 17.4 / 55.0 * absLat,
                62 - 7.16 / 55.0 * absLat,
                62 + 5.12 / 55.0 * absLat,
                62 + 19.44 / 55.0 * absLat,
            ]
        case .abyad:
            return [
                75 + 25.6 / 55.0 * absLat,
                75 + 7.16 / 55.0 * absLat,
                75 + 36.84 / 55.0 * absLat,
                75 + 81.84 / 55.0 * absLat,
            ]
        case .general:
            return [
                75 + 25.6 / 55.0 * absLat,
                75 + 2.05 / 55.0 * absLat,
                75 - 9.21 / 55.0 * absLat,
                75 + 6.14 / 55.0 * absLat,
            ]
        }
    }
}
