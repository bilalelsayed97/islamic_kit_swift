import XCTest
import IslamicKitPlus

final class AstronomyTests: XCTestCase {
    // MARK: Julian day

    func testMeeusExample7a() {
        XCTAssertEqual(Astronomical.julianDay(1957, 10, 4, 0.81 * 24), 2436116.31, accuracy: 0.00001)
    }

    func testJ2000Epoch() {
        XCTAssertEqual(Astronomical.julianDay(2000, 1, 1, 12), 2451545.0)
        XCTAssertEqual(Astronomical.julianCentury(2451545.0), 0.0)
    }

    func testJulianCenturyIs36525Days() {
        XCTAssertEqual(Astronomical.julianCentury(2451545.0 + 36525), 1.0, accuracy: 1e-12)
    }

    // MARK: Meeus example 25.a — solar position for 1992-10-13 at 0h TD

    private let jd = Astronomical.julianDay(1992, 10, 13)
    private var t: Double { Astronomical.julianCentury(jd) }

    func testJulianDayAndCentury() {
        XCTAssertEqual(jd, 2448908.5)
        XCTAssertEqual(t, -0.072183436, accuracy: 1e-9)
    }

    func testGeometricMeanLongitude() {
        XCTAssertEqual(Astronomical.meanSolarLongitude(t), 201.80720, accuracy: 0.00001)
    }

    func testMeanAnomaly() {
        XCTAssertEqual(Astronomical.meanSolarAnomaly(t), 278.99397, accuracy: 0.00001)
    }

    func testEquationOfTheCentre() {
        let m = Astronomical.meanSolarAnomaly(t)
        XCTAssertEqual(Astronomical.solarEquationOfTheCenter(t, m), -1.89732, accuracy: 0.00001)
    }

    func testApparentLongitude() {
        let l0 = Astronomical.meanSolarLongitude(t)
        XCTAssertEqual(Astronomical.apparentSolarLongitude(t, l0), 199.90895, accuracy: 0.00002)
    }

    func testMeanObliquityOfTheEcliptic() {
        XCTAssertEqual(Astronomical.meanObliquityOfTheEcliptic(t), 23.44023, accuracy: 0.00001)
    }

    func testApparentRightAscensionAndDeclination() {
        let solar = SolarCoordinates(julianDay: jd)
        XCTAssertEqual(solar.rightAscension, 198.38083, accuracy: 0.00001)
        XCTAssertEqual(solar.declination, -7.78507, accuracy: 0.00001)
    }

    // MARK: Angle helpers

    func testUnwindAngleWrapsInto0To360() {
        XCTAssertEqual(Astronomical.unwindAngle(-45), 315)
        XCTAssertEqual(Astronomical.unwindAngle(361), 1, accuracy: 1e-12)
        XCTAssertEqual(Astronomical.unwindAngle(360), 0)
    }

    func testClosestAngleMapsIntoMinus180To180() {
        XCTAssertEqual(Astronomical.closestAngle(360), 0)
        XCTAssertEqual(Astronomical.closestAngle(361), 1, accuracy: 1e-12)
        XCTAssertEqual(Astronomical.closestAngle(-370), -10, accuracy: 1e-12)
        XCTAssertEqual(Astronomical.closestAngle(180), 180)
    }

    func testJavaRoundBreaksTiesUpward() {
        XCTAssertEqual(Astronomical.javaRound(0.5), 1)
        XCTAssertEqual(Astronomical.javaRound(-0.5), 0)
        XCTAssertEqual(Int((-0.5).rounded()), -1) // the behaviour we must not use
        XCTAssertEqual(Astronomical.javaRound(2.4), 2)
    }

    func testArccosOutOfDomainIsNaN() {
        XCTAssertTrue(Astronomical.arccos(1.5).isNaN)
    }

    // MARK: SolarTime

    private let raleigh = Coordinates(35.7750, -78.6336)

    func testSunriseAndSunsetBracketTransit() {
        let solar = SolarTime(year: 2015, month: 7, day: 12, coordinates: raleigh)
        XCTAssertLessThan(solar.sunrise, solar.transit)
        XCTAssertLessThan(solar.transit, solar.sunset)
    }

    func testHanafiAsrFallsLaterThanShafi() {
        let solar = SolarTime(year: 2015, month: 7, day: 12, coordinates: raleigh)
        XCTAssertGreaterThan(solar.afternoon(2), solar.afternoon(1))
    }

    func testUnreachableAngleYieldsNaN() {
        // Stockholm at the solstice never reaches 18° below the horizon.
        let solar = SolarTime(year: 2024, month: 6, day: 21, coordinates: Coordinates(59.3293, 18.0686))
        XCTAssertFalse(solar.sunrise.isNaN)
        XCTAssertTrue(solar.hourAngle(-18, afterTransit: false).isNaN)
    }

    func testElevationBringsSunriseEarlierAndSunsetLater() {
        let coordinates = Coordinates(21.4225, 39.8262)
        let sea = SolarTime(year: 2024, month: 6, day: 21, coordinates: coordinates)
        let high = SolarTime(year: 2024, month: 6, day: 21, coordinates: coordinates, elevation: 1000)
        XCTAssertLessThan(high.sunrise, sea.sunrise)
        XCTAssertGreaterThan(high.sunset, sea.sunset)
        XCTAssertEqual(high.transit, sea.transit)
    }

    // MARK: Moonsighting twilight

    func testMoonsightingSeasonalSeconds() {
        let twilight = MoonsightingTwilight()
        let date = CivilDate(year: 2014, month: 4, day: 24)
        // Day-of-year 114 → dyy 124 (91 ≤ dyy < 137 band); London latitude.
        XCTAssertEqual(twilight.fajrSecondsBeforeSunrise(date, latitude: 51.508515), 6128)
        XCTAssertEqual(twilight.ishaSecondsAfterSunset(date, latitude: 0, shafaq: .general), 75 * 60)
        XCTAssertEqual(twilight.ishaSecondsAfterSunset(date, latitude: 0, shafaq: .ahmer), 62 * 60)
        // Southern hemisphere wraps around the June solstice: both dates are
        // day 0 since their hemisphere's solstice, so they agree at |lat| 33.
        XCTAssertEqual(twilight.fajrSecondsBeforeSunrise(CivilDate(year: 2023, month: 6, day: 21), latitude: -33),
                       twilight.fajrSecondsBeforeSunrise(CivilDate(year: 2023, month: 12, day: 21), latitude: 33))
    }
}
