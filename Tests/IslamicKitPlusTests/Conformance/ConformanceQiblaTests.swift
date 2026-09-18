import XCTest
@testable import IslamicKitPlus

/// `qibla.json`: bearings for 45 coordinates including the poles, the
/// antimeridian and Makkah itself.
final class ConformanceQiblaTests: XCTestCase {
    private struct File: Decodable {
        let cases: [Case]
    }

    private struct Case: Decodable {
        let lat: Double
        let lng: Double
        let degrees: Double
    }

    func testBearingsMatchWithin1e9() throws {
        let file: File = try ConformanceFixtures.load("qibla")
        XCTAssertEqual(file.cases.count, 45)
        let calculator = QiblaCalculator()
        for c in file.cases {
            let q = calculator.direction(Coordinates(c.lat, c.lng))
            assertClose(q.degrees, c.degrees, accuracy: 1e-9, "qibla(\(c.lat), \(c.lng))")
        }
    }
}
