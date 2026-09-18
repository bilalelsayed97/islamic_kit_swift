import Foundation

/// Degree-based trigonometry and the solar-position formulas of Jean Meeus'
/// *Astronomical Algorithms* (2nd ed.).
///
/// Every angle is in degrees unless the name says otherwise; times are
/// fractional hours. The constants, the operation order and the
/// integer-truncation points are all deliberate — they keep results agreeing
/// with the published reference to the second.
public enum Astronomical {
    private static let degToRad = Double.pi / 180.0
    private static let radToDeg = 180.0 / Double.pi

    /// Altitude of the sun's centre at apparent sunrise/sunset: −0.833°, which
    /// folds together atmospheric refraction and the solar semi-diameter.
    public static let horizonAltitude = -0.833333333333333

    // MARK: Degree trigonometry

    public static func sin(_ degrees: Double) -> Double { Foundation.sin(degrees * degToRad) }

    public static func cos(_ degrees: Double) -> Double { Foundation.cos(degrees * degToRad) }

    public static func tan(_ degrees: Double) -> Double { Foundation.tan(degrees * degToRad) }

    public static func arcsin(_ value: Double) -> Double { Foundation.asin(value) * radToDeg }

    /// Returns NaN outside `[-1, 1]` (no clamping), which the callers rely on.
    public static func arccos(_ value: Double) -> Double { Foundation.acos(value) * radToDeg }

    public static func arctan(_ value: Double) -> Double { Foundation.atan(value) * radToDeg }

    public static func arctan2(_ y: Double, _ x: Double) -> Double { Foundation.atan2(y, x) * radToDeg }

    // MARK: Numeric helpers

    /// Rounds half **up**, i.e. `floor(x + 0.5)`.
    ///
    /// Swift's `rounded()` rounds half *away from zero*, which disagrees on
    /// exact negative halves (`-0.5` → `0` here, `-1` there). The published
    /// tables assume half-up, so every rounding step goes through this.
    public static func javaRound(_ value: Double) -> Int { IntegerMath.javaRound(value) }

    /// Wraps `value` into `[0, max)`.
    public static func normalizeWithBound(_ value: Double, _ max: Double) -> Double {
        value - max * (value / max).rounded(.down)
    }

    /// Wraps an angle into `[0, 360)`.
    public static func unwindAngle(_ value: Double) -> Double { normalizeWithBound(value, 360.0) }

    /// Maps an angle into `[-180, 180]`.
    public static func closestAngle(_ angle: Double) -> Double {
        if angle >= -180.0 && angle <= 180.0 { return angle }
        return angle - 360.0 * Double(javaRound(angle / 360.0))
    }

    // MARK: Julian day

    /// Julian Day for a Gregorian calendar date at `hours` UTC.
    ///
    /// Meeus, *Astronomical Algorithms*, chapter 7. The integer truncations are
    /// intentional — the formula is defined in terms of them.
    public static func julianDay(_ year: Int, _ month: Int, _ day: Int, _ hours: Double = 0) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = y / 100
        let b = (2 - a) + (a / 4)

        return (Double(y + 4716) * 365.25).rounded(.towardZero)
            + (Double(m + 1) * 30.6001).rounded(.towardZero)
            + (Double(day) + hours / 24.0)
            + Double(b)
            - 1524.5
    }

    /// Julian centuries since the J2000.0 epoch.
    public static func julianCentury(_ julianDay: Double) -> Double {
        (julianDay - 2451545.0) / 36525.0
    }

    // MARK: Solar position (Meeus)

    /// Geometric mean longitude of the sun, in degrees.
    public static func meanSolarLongitude(_ t: Double) -> Double {
        unwindAngle(280.4664567 + 36000.76983 * t + 0.0003032 * t * t)
    }

    /// Geometric mean longitude of the moon, in degrees.
    public static func meanLunarLongitude(_ t: Double) -> Double {
        unwindAngle(218.3165 + 481267.8813 * t)
    }

    /// Mean anomaly of the sun, in degrees.
    public static func meanSolarAnomaly(_ t: Double) -> Double {
        unwindAngle(357.52911 + 35999.05029 * t - 0.0001537 * t * t)
    }

    /// Longitude of the ascending node of the lunar orbit, in degrees.
    public static func ascendingLunarNodeLongitude(_ t: Double) -> Double {
        unwindAngle(125.04452 - 1934.136261 * t + 0.0020708 * t * t + (t * t * t) / 450000.0)
    }

    /// The sun's equation of the centre, in degrees, for mean anomaly `m`.
    public static func solarEquationOfTheCenter(_ t: Double, _ m: Double) -> Double {
        let mRad = m * degToRad
        return (1.914602 - 0.004817 * t - 0.000014 * t * t) * Foundation.sin(mRad)
            + (0.019993 - 0.000101 * t) * Foundation.sin(2 * mRad)
            + 0.000289 * Foundation.sin(3 * mRad)
    }

    /// Apparent longitude of the sun (nutation and aberration applied).
    public static func apparentSolarLongitude(_ t: Double, _ meanLongitude: Double) -> Double {
        let longitude = meanLongitude
            + solarEquationOfTheCenter(t, meanSolarAnomaly(t))
            - 0.00569
            - 0.00478 * sin(125.04 - 1934.136 * t)
        return unwindAngle(longitude)
    }

    /// Mean obliquity of the ecliptic, in degrees.
    public static func meanObliquityOfTheEcliptic(_ t: Double) -> Double {
        23.439291 - 0.013004167 * t - 0.0000001639 * t * t + 0.0000005036 * t * t * t
    }

    /// Apparent obliquity of the ecliptic, in degrees.
    public static func apparentObliquityOfTheEcliptic(_ t: Double, _ meanObliquity: Double) -> Double {
        meanObliquity + 0.00256 * cos(125.04 - 1934.136 * t)
    }

    /// Mean sidereal time at Greenwich, in degrees.
    public static func meanSiderealTime(_ t: Double) -> Double {
        let jd = t * 36525.0 + 2451545.0
        let theta = 280.46061837
            + 360.98564736629 * (jd - 2451545.0)
            + 0.000387933 * t * t
            - (t * t * t) / 38710000.0
        return unwindAngle(theta)
    }

    /// Nutation in longitude, in degrees.
    public static func nutationInLongitude(
        _ t: Double, _ solarLongitude: Double, _ lunarLongitude: Double, _ ascendingNode: Double
    ) -> Double {
        (-17.2 / 3600) * sin(ascendingNode)
            - (1.32 / 3600) * sin(2 * solarLongitude)
            - (0.23 / 3600) * sin(2 * lunarLongitude)
            + (0.21 / 3600) * sin(2 * ascendingNode)
    }

    /// Nutation in obliquity, in degrees.
    public static func nutationInObliquity(
        _ t: Double, _ solarLongitude: Double, _ lunarLongitude: Double, _ ascendingNode: Double
    ) -> Double {
        (9.2 / 3600) * cos(ascendingNode)
            + (0.57 / 3600) * cos(2 * solarLongitude)
            + (0.10 / 3600) * cos(2 * lunarLongitude)
            - (0.09 / 3600) * cos(2 * ascendingNode)
    }

    /// Altitude of a celestial body above the horizon, in degrees.
    public static func altitudeOfCelestialBody(
        _ observerLatitude: Double, _ declination: Double, _ localHourAngle: Double
    ) -> Double {
        arcsin(
            sin(observerLatitude) * sin(declination)
                + cos(observerLatitude) * cos(declination) * cos(localHourAngle)
        )
    }

    // MARK: Transit and hour angles

    /// Approximate transit as a fraction of the day.
    public static func approximateTransit(
        _ longitude: Double, _ siderealTime: Double, _ rightAscension: Double
    ) -> Double {
        let lw = longitude * -1
        return normalizeWithBound((rightAscension + lw - siderealTime) / 360, 1)
    }

    /// Transit time (fractional hours) corrected by interpolation.
    public static func correctedTransit(
        _ approximateTransit: Double,
        _ longitude: Double,
        _ siderealTime: Double,
        _ rightAscension: Double,
        _ previousRightAscension: Double,
        _ nextRightAscension: Double
    ) -> Double {
        let lw = longitude * -1
        let theta = unwindAngle(siderealTime + 360.985647 * approximateTransit)
        let alpha = unwindAngle(
            interpolateAngles(rightAscension, previousRightAscension, nextRightAscension, approximateTransit)
        )
        let h = closestAngle(theta - lw - alpha)
        let deltaM = h / -360
        return (approximateTransit + deltaM) * 24
    }

    /// Time (fractional hours) at which the sun reaches altitude `altitude`.
    ///
    /// Returns NaN when the sun never reaches that altitude on the day.
    public static func correctedHourAngle(
        approximateTransit: Double,
        altitude: Double,
        latitude: Double,
        longitude: Double,
        afterTransit: Bool,
        siderealTime: Double,
        rightAscension: Double,
        previousRightAscension: Double,
        nextRightAscension: Double,
        declination: Double,
        previousDeclination: Double,
        nextDeclination: Double
    ) -> Double {
        let lw = longitude * -1

        let term = (sin(altitude) - sin(latitude) * sin(declination)) / (cos(latitude) * cos(declination))
        // acos() outside [-1, 1] yields NaN, which propagates: the caller treats a
        // NaN result as "the sun never reaches this angle today".
        let h0 = arccos(term) / 360

        let m = afterTransit ? approximateTransit + h0 : approximateTransit - h0
        let theta = unwindAngle(siderealTime + 360.985647 * m)
        let alpha = unwindAngle(
            interpolateAngles(rightAscension, previousRightAscension, nextRightAscension, m)
        )
        let delta = interpolate(declination, previousDeclination, nextDeclination, m)
        let h = (theta - lw) - alpha
        let altitudeOfSun = altitudeOfCelestialBody(latitude, delta, h)
        let deltaM = (altitudeOfSun - altitude) / (360 * cos(delta) * cos(latitude) * sin(h))
        return (m + deltaM) * 24
    }

    /// Three-point interpolation of a value. Meeus chapter 3.
    public static func interpolate(
        _ value: Double, _ previousValue: Double, _ nextValue: Double, _ factor: Double
    ) -> Double {
        let a = value - previousValue
        let b = nextValue - value
        let c = b - a
        return value + ((factor / 2) * (a + b + factor * c))
    }

    /// Three-point interpolation of an angle (each difference unwound first).
    public static func interpolateAngles(
        _ value: Double, _ previousValue: Double, _ nextValue: Double, _ factor: Double
    ) -> Double {
        let a = unwindAngle(value - previousValue)
        let b = unwindAngle(nextValue - value)
        let c = b - a
        return value + ((factor / 2) * (a + b + factor * c))
    }
}
