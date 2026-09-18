/// A geocoded city from the bundled dataset (or a custom `Geocoder`).
public struct City: Hashable, Sendable, CustomStringConvertible {
    public let name: String

    /// Arabic city name, if known (from the bundled database).
    public let nameAr: String?

    /// ISO 3166-1 alpha-2 country code, e.g. `"GB"`.
    public let country: String

    /// Administrative region / state, if known.
    public let state: String?

    public let coordinates: Coordinates

    /// Standard-time UTC offset for the city (does **not** account for DST;
    /// override per-date if you need DST-correct results).
    public let utcOffset: UTCOffset

    public init(
        name: String,
        country: String,
        coordinates: Coordinates,
        utcOffset: UTCOffset,
        nameAr: String? = nil,
        state: String? = nil
    ) {
        self.name = name
        self.nameAr = nameAr
        self.country = country
        self.state = state
        self.coordinates = coordinates
        self.utcOffset = utcOffset
    }

    public var description: String {
        "City(\(name)\(state.map { ", \($0)" } ?? ""), \(country))"
    }
}
