import Foundation

/// Solar events for one civil date at one location, in fractional **UTC**
/// hours measured from 00:00 UTC of that date.
///
/// Coordinates are computed for the previous, current and next day so that
/// right ascension and declination can be interpolated to the moment of each
/// event — the step that separates this from single-sample approximations and
/// keeps results accurate to the second.
///
/// Values may fall outside `[0, 24)` when an event lands on an adjacent UTC
/// day; the raw value is kept so day rollover survives. A NaN result means the
/// sun never reaches the requested altitude on that date.
public struct SolarTime: Sendable {
    public let coordinates: Coordinates
    private let solar: SolarCoordinates
    private let previous: SolarCoordinates
    private let next: SolarCoordinates

    /// Approximate transit as a fraction of the day (interpolation seed).
    public let approximateTransit: Double

    /// Solar transit — Dhuhr's astronomical basis. Fractional UTC hours.
    public let transit: Double

    /// Apparent sunrise, fractional UTC hours.
    public let sunrise: Double

    /// Apparent sunset, fractional UTC hours.
    public let sunset: Double

    /// Computes the solar events for `year`/`month`/`day` at `coordinates`.
    ///
    /// `elevation` is the observer's height above sea level in metres. It dips
    /// the apparent horizon by `0.0347 · √metres` degrees, bringing sunrise
    /// earlier and sunset later. This is a package extension the reference
    /// standard algorithm does not model; at `0` the behaviour is identical.
    public init(year: Int, month: Int, day: Int, coordinates: Coordinates, elevation: Double = 0) {
        let julianDay = Astronomical.julianDay(year, month, day)
        // JD is continuous, so ±1 is exactly the adjacent civil day at 0h UTC.
        let solar = SolarCoordinates(julianDay: julianDay)
        let previous = SolarCoordinates(julianDay: julianDay - 1)
        let next = SolarCoordinates(julianDay: julianDay + 1)

        let approximateTransit = Astronomical.approximateTransit(
            coordinates.longitude, solar.apparentSiderealTime, solar.rightAscension
        )

        let transit = Astronomical.correctedTransit(
            approximateTransit,
            coordinates.longitude,
            solar.apparentSiderealTime,
            solar.rightAscension,
            previous.rightAscension,
            next.rightAscension
        )

        let horizon = elevation > 0
            ? Astronomical.horizonAltitude - 0.0347 * elevation.squareRoot()
            : Astronomical.horizonAltitude

        self.coordinates = coordinates
        self.solar = solar
        self.previous = previous
        self.next = next
        self.approximateTransit = approximateTransit
        self.transit = transit
        self.sunrise = SolarTime.angleTime(
            horizon, afterTransit: false, coordinates: coordinates,
            approximateTransit: approximateTransit, solar: solar, previous: previous, next: next
        )
        self.sunset = SolarTime.angleTime(
            horizon, afterTransit: true, coordinates: coordinates,
            approximateTransit: approximateTransit, solar: solar, previous: previous, next: next
        )
    }

    /// Convenience for a `CivilDate`.
    public init(date: CivilDate, coordinates: Coordinates, elevation: Double = 0) {
        self.init(year: date.year, month: date.month, day: date.day, coordinates: coordinates, elevation: elevation)
    }

    private static func angleTime(
        _ altitude: Double,
        afterTransit: Bool,
        coordinates: Coordinates,
        approximateTransit: Double,
        solar: SolarCoordinates,
        previous: SolarCoordinates,
        next: SolarCoordinates
    ) -> Double {
        Astronomical.correctedHourAngle(
            approximateTransit: approximateTransit,
            altitude: altitude,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            afterTransit: afterTransit,
            siderealTime: solar.apparentSiderealTime,
            rightAscension: solar.rightAscension,
            previousRightAscension: previous.rightAscension,
            nextRightAscension: next.rightAscension,
            declination: solar.declination,
            previousDeclination: previous.declination,
            nextDeclination: next.declination
        )
    }

    /// Time at which the sun's centre sits at `altitude` degrees (negative =
    /// below the horizon), before or after transit. Fractional UTC hours.
    public func hourAngle(_ altitude: Double, afterTransit: Bool) -> Double {
        SolarTime.angleTime(
            altitude, afterTransit: afterTransit, coordinates: coordinates,
            approximateTransit: approximateTransit, solar: solar, previous: previous, next: next
        )
    }

    /// Time at which an object's shadow has grown by `shadowFactor` times its
    /// own length beyond its shadow at transit — the Asr definition (1 for
    /// Shafi'i/Maliki/Hanbali, 2 for Hanafi). Fractional UTC hours.
    public func afternoon(_ shadowFactor: Double) -> Double {
        let tangent = Swift.abs(coordinates.latitude - solar.declination)
        let inverse = shadowFactor + Astronomical.tan(tangent)
        return hourAngle(Astronomical.arctan(1.0 / inverse), afterTransit: true)
    }
}
