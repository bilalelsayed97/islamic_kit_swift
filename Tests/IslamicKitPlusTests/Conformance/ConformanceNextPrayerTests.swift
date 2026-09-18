import XCTest
@testable import IslamicKitPlus

/// `next_prayer.json`: 90 `(from, coords, params)` cases including the
/// after-Isha rollover to the next day's Fajr.
final class ConformanceNextPrayerTests: XCTestCase {
    private struct File: Decodable {
        let cases: [Case]
    }

    private struct Case: Decodable {
        let id: String
        let from: String
        let lat: Double
        let lng: Double
        let params: FixtureParams
        let prayer: String
        let hours: Double?
        let formatted: String
        let onDate: String
    }

    func testNextPrayerMatches() throws {
        let file: File = try ConformanceFixtures.load("next_prayer")
        XCTAssertEqual(file.cases.count, 90)
        let service = PrayerTimesService()
        for c in file.cases {
            let next = try service.nextPrayer(
                ConformanceFixtures.dateTime(c.from), Coordinates(c.lat, c.lng), c.params.toCalculationParameters()
            )
            assertSame(next.prayer.key, c.prayer, "\(c.id) prayer")
            assertSame(next.time.hours, c.hours, "\(c.id) hours")
            assertSame(next.time.format(), c.formatted, "\(c.id) formatted")
            assertSame(next.onDate.isoString, c.onDate, "\(c.id) onDate")
        }
    }
}
