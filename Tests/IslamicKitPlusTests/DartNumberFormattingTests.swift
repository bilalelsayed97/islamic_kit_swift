import XCTest
import IslamicKitPlus

final class DartNumberFormattingTests: XCTestCase {
    func testMatchesDartDoubleToString() {
        let cases: [(Double, String)] = [
            (3.95, "3.95"),
            (13.0, "13.0"),
            (-0.5, "-0.5"),
            (0.1, "0.1"),
            (1e-5, "0.00001"),
            (1e-6, "0.000001"),
            (1e-7, "1e-7"),
            (1.5e-7, "1.5e-7"),
            (1e16, "10000000000000000.0"),
            (1e20, "100000000000000000000.0"),
            (1e21, "1e+21"),
            (1.25e22, "1.25e+22"),
            (51.508515, "51.508515"),
            (39.70421229999999, "39.70421229999999"),
            (-86.39943869999999, "-86.39943869999999"),
            (0, "0.0"),
            (-0.0, "-0.0"),
            (123456789.125, "123456789.125"),
            (0.5 / 60, "0.008333333333333333"),
            (24.000000000000004, "24.000000000000004"),
            (5e-324, "5e-324"),
            (1.7976931348623157e308, "1.7976931348623157e+308"),
        ]
        for (value, expected) in cases {
            XCTAssertEqual(DartNumberFormatting.string(value), expected, "\(value)")
        }
        XCTAssertEqual(DartNumberFormatting.string(.nan), "NaN")
        XCTAssertEqual(DartNumberFormatting.string(.infinity), "Infinity")
        XCTAssertEqual(DartNumberFormatting.string(-.infinity), "-Infinity")
    }

    func testRoundTrips() {
        for value in stride(from: -30.0, through: 50.0, by: 0.0175) {
            XCTAssertEqual(Double(DartNumberFormatting.string(value)), value)
        }
    }
}
