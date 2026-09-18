import XCTest
@testable import IslamicKitPlus

/// `moonsighting.json`: Moonsighting Committee twilight seconds for a
/// latitude × day-of-year grid over a common and a leap year.
final class ConformanceMoonsightingTests: XCTestCase {
    private struct File: Decodable {
        let cases: [Case]
    }

    private struct Case: Decodable {
        let date: String
        let lat: Double
        let fajrSeconds: Int
        let ishaSeconds: [String: Int]
    }

    func testTwilightSecondsMatchExactly() throws {
        let file: File = try ConformanceFixtures.load("moonsighting")
        XCTAssertEqual(file.cases.count, 1332)
        let twilight = MoonsightingTwilight()
        for c in file.cases {
            let date = ConformanceFixtures.date(c.date)
            let id = "\(c.date) lat \(c.lat)"
            assertSame(twilight.fajrSecondsBeforeSunrise(date, latitude: c.lat), c.fajrSeconds, "\(id) fajr")
            for shafaq in Shafaq.allCases {
                assertSame(
                    twilight.ishaSecondsAfterSunset(date, latitude: c.lat, shafaq: shafaq),
                    c.ishaSeconds[shafaq.code],
                    "\(id) isha \(shafaq.code)"
                )
            }
        }
    }
}
