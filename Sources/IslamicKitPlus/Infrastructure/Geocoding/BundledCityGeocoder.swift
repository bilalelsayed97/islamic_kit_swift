/// Offline `Geocoder` backed by the curated `CityDataset`.
///
/// Matching is name-based: exact, prefix, then substring, best-first. For
/// free-text addresses it also tries each comma-separated segment, so
/// `"Trafalgar Square, London, UK"` still resolves to London.
public struct BundledCityGeocoder: Geocoder {
    private let cities: [CityRecord]

    /// Uses `cities`, or the bundled dataset when `nil`.
    public init(_ cities: [CityRecord]? = nil) {
        self.cities = cities ?? CityDataset.records
    }

    public func search(_ query: String, country: String?, state: String?) -> [City] {
        let candidates = GeocoderMatching.candidates(query)
        if candidates.isEmpty { return [] }

        let countryCode = GeocoderMatching.resolveCountry(country)
        let normState = state.map(GeocoderMatching.normalize)

        var scored = [(city: City, score: Int, index: Int)]()
        for (index, record) in cities.enumerated() {
            if let code = countryCode, record.country.uppercased() != code { continue }
            if let wanted = normState {
                guard let s = record.state, GeocoderMatching.normalize(s) == wanted else { continue }
            }
            if let score = GeocoderMatching.score(GeocoderMatching.normalize(record.name), candidates) {
                scored.append((toCity(record), score, index))
            }
        }

        // Dart's sort leaves equal scores in unspecified order; the dataset
        // index is a deterministic tiebreak.
        scored.sort { a, b in
            a.score != b.score ? a.score < b.score : a.index < b.index
        }
        return scored.map(\.city)
    }

    private func toCity(_ r: CityRecord) -> City {
        City(
            name: r.name,
            country: r.country,
            coordinates: Coordinates(r.lat, r.lng),
            utcOffset: UTCOffset(seconds: r.offsetMinutes * 60),
            state: r.state
        )
    }
}
