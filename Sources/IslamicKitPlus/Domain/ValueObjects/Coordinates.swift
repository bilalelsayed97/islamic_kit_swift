/// An immutable geographic coordinate in decimal degrees.
public struct Coordinates: Hashable, Sendable, CustomStringConvertible {
    /// Latitude in decimal degrees, positive north.
    public var latitude: Double

    /// Longitude in decimal degrees, positive east.
    public var longitude: Double

    public init(_ latitude: Double, _ longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public var description: String {
        "Coordinates(\(DartNumberFormatting.string(latitude)), \(DartNumberFormatting.string(longitude)))"
    }
}
