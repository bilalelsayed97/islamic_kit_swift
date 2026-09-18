import XCTest
import IslamicKitPlus

final class QiblaTests: XCTestCase {
    func testQiblaFromLondonMatchesReference() {
        let service = PrayerTimesService()
        let qibla = service.qibla(Coordinates(51.5073509, -0.1277583))
        XCTAssertEqual(qibla.degrees, 118.98724271029, accuracy: 1e-6)
    }

    func testQiblaIsNormalizedTo0To360() {
        let calculator = QiblaCalculator()
        let q = calculator.direction(Coordinates(-33.8688, 151.2093))
        XCTAssertTrue((0...360).contains(q.degrees))
        XCTAssertEqual(q.from, Coordinates(-33.8688, 151.2093))
    }

    func testKaabaConstant() {
        XCTAssertEqual(QiblaCalculator.kaaba, Coordinates(21.422517, 39.826166))
        XCTAssertEqual(QiblaCalculator().direction(Coordinates(51.5073509, -0.1277583)).description.prefix(23),
                       "QiblaDirection(118.99° ")
    }
}
