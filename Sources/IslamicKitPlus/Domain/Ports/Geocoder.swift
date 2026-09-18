/// Resolves free-text locations (addresses / city names) to coordinates.
///
/// The default `BundledCityGeocoder` uses an offline dataset, but any
/// implementation can be injected (Dependency Inversion) — including one that
/// wraps an online service in an app that allows network access.
public protocol Geocoder: Sendable {
    /// Returns all matches for `query`, optionally filtered by `country`
    /// (ISO-3166 alpha-2 or a common name) and `state`. Ordered best-match first.
    func search(_ query: String, country: String?, state: String?) -> [City]
}

extension Geocoder {
    /// `search(_:country:state:)` with no filters.
    public func search(_ query: String) -> [City] {
        search(query, country: nil, state: nil)
    }

    /// `search(_:country:state:)` filtered by country only.
    public func search(_ query: String, country: String?) -> [City] {
        search(query, country: country, state: nil)
    }

    /// The single best match for `query`, or `nil` if none.
    public func resolve(_ query: String, country: String? = nil, state: String? = nil) -> City? {
        search(query, country: country, state: state).first
    }
}
