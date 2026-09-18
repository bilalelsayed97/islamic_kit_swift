import Foundation

/// The direction of the Qibla from an observer's location.
public struct QiblaDirection: Hashable, Sendable, CustomStringConvertible {
    /// Bearing to the Ka'aba measured clockwise from true north, in `[0, 360)`.
    public let degrees: Double

    /// The observer's location.
    public let from: Coordinates

    public init(degrees: Double, from: Coordinates) {
        self.degrees = degrees
        self.from = from
    }

    public var description: String {
        "QiblaDirection(\(String(format: "%.2f", locale: nil, degrees))° from "
            + "\(DartNumberFormatting.string(from.latitude)), \(DartNumberFormatting.string(from.longitude)))"
    }
}
