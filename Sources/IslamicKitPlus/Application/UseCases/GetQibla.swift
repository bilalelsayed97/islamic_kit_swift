import Foundation

/// Computes the Qibla direction (great-circle bearing to the Ka'aba).
public struct QiblaCalculator: Sendable {
    /// Geographic coordinates of the Ka'aba, in degrees.
    public static let kaaba = Coordinates(21.422517, 39.826166)

    public init() {}

    public func direction(_ from: Coordinates) -> QiblaDirection {
        let a = dtr(QiblaCalculator.kaaba.longitude - from.longitude)
        let b = dtr(90 - from.latitude)
        let c = dtr(90 - QiblaCalculator.kaaba.latitude)
        var degrees = rtd(
            atan2(
                sin(a),
                sin(b) * cot(c) - cos(b) * cos(a)
            )
        )
        if degrees < 0 { degrees += 360 }
        return QiblaDirection(degrees: degrees, from: from)
    }

    private func dtr(_ d: Double) -> Double { d * Double.pi / 180.0 }
    private func rtd(_ r: Double) -> Double { r * 180.0 / Double.pi }
    private func cot(_ x: Double) -> Double { tan(Double.pi / 2 - x) }
}
