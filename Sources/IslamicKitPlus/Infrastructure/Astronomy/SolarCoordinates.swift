/// The sun's apparent equatorial coordinates for one Julian Day.
///
/// All three values are needed to interpolate the sun's position across a day,
/// which is what gives the Meeus algorithm its accuracy over the simpler
/// single-sample formulas.
public struct SolarCoordinates: Sendable {
    /// Apparent declination of the sun, in degrees.
    public let declination: Double

    /// Apparent right ascension of the sun, in degrees.
    public let rightAscension: Double

    /// Apparent sidereal time at Greenwich, in degrees.
    public let apparentSiderealTime: Double

    /// Computes the sun's coordinates for `julianDay`.
    public init(julianDay: Double) {
        let t = Astronomical.julianCentury(julianDay)
        let meanSolarLongitude = Astronomical.meanSolarLongitude(t)
        let meanLunarLongitude = Astronomical.meanLunarLongitude(t)
        let ascendingNode = Astronomical.ascendingLunarNodeLongitude(t)
        let apparentLongitude = Astronomical.apparentSolarLongitude(t, meanSolarLongitude)

        let meanSiderealTime = Astronomical.meanSiderealTime(t)
        let nutationLongitude = Astronomical.nutationInLongitude(
            t, meanSolarLongitude, meanLunarLongitude, ascendingNode
        )
        let nutationObliquity = Astronomical.nutationInObliquity(
            t, meanSolarLongitude, meanLunarLongitude, ascendingNode
        )

        let meanObliquity = Astronomical.meanObliquityOfTheEcliptic(t)
        let apparentObliquity = Astronomical.apparentObliquityOfTheEcliptic(t, meanObliquity)

        // Meeus equations 25.6 / 25.7 — apparent declination and right ascension.
        declination = Astronomical.arcsin(
            Astronomical.sin(apparentObliquity) * Astronomical.sin(apparentLongitude)
        )
        rightAscension = Astronomical.unwindAngle(
            Astronomical.arctan2(
                Astronomical.cos(apparentObliquity) * Astronomical.sin(apparentLongitude),
                Astronomical.cos(apparentLongitude)
            )
        )
        apparentSiderealTime = meanSiderealTime
            + (nutationLongitude * 3600 * Astronomical.cos(meanObliquity + nutationObliquity)) / 3600
    }
}
