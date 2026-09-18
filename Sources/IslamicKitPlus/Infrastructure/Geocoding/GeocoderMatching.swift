/// Name-matching helpers shared by the curated `BundledCityGeocoder` and the
/// SQLite geocoder in `IslamicKitPlusGeocoding`. Each reproduces the private
/// Dart helper of the same name, on UTF-16 code units so that prefix and
/// substring tests agree with Dart's `String` semantics.
package enum GeocoderMatching {
    /// Dart `_normalize`: trim, lower-case, collapse whitespace runs to one
    /// space.
    package static func normalize(_ s: String) -> String {
        StringHelpers.normalize(s)
    }

    /// Dart `_candidates`: the normalised query followed by each distinct
    /// non-empty comma-separated segment.
    package static func candidates(_ query: String) -> [String] {
        let full = normalize(query)
        if full.isEmpty { return [] }
        var parts = [full]
        for seg in query.split(separator: ",", omittingEmptySubsequences: false) {
            let n = normalize(String(seg))
            if !n.isEmpty && !parts.contains(n) { parts.append(n) }
        }
        return parts
    }

    /// Dart `_score`: best (lowest) match score of `name` against any
    /// candidate — 0 exact, 1 prefix, 2 name inside candidate, 3 candidate
    /// inside name — or `nil` when nothing matches.
    package static func score(_ name: String, _ candidates: [String]) -> Int? {
        var best: Int?
        for c in candidates {
            var s: Int?
            if name == c {
                s = 0
            } else if StringHelpers.utf16HasPrefix(name, c) {
                s = 1
            } else if StringHelpers.utf16Contains(c, name) {
                s = 2
            } else if StringHelpers.utf16Contains(name, c) {
                s = 3
            }
            if let s = s, s < (best ?? Int.max) { best = s }
        }
        return best
    }

    /// Dart `_resolveCountry`: a two-character input is taken as an ISO code
    /// (so `"uk"` is *not* aliased); otherwise a common-name alias, else the
    /// upper-cased input as-is. `nil` in, `nil` out.
    package static func resolveCountry(_ country: String?) -> String? {
        guard let country = country else { return nil }
        let normalized = normalize(country)
        if StringHelpers.utf16Length(normalized) == 2 { return normalized.uppercased() }
        return CityDataset.countryAliases[normalized]?.uppercased() ?? normalized.uppercased()
    }

    /// Dart `_placeRank`: orders settlement feature codes by prominence,
    /// lowest first.
    package static func placeRank(_ level: String?) -> Int {
        switch level {
        case "PPLC": return 0 // national capital
        case "PPLA": return 1 // first-order administrative capital
        case "PPLA2": return 2
        case "PPLA3": return 3
        case "PPLA4": return 4
        case "PPL": return 5
        default: return 6
        }
    }

    /// Dart `_offsetMinutes`: the standard-time offset in minutes, taking the
    /// fractional-zone override by IANA id before the truncated hour column.
    package static func offsetMinutes(timeZoneId: String?, hours: Double?) -> Int {
        if let id = timeZoneId, !id.isEmpty, let minutes = CountryIsoMap.fractionalZoneOffsetMinutes[id] {
            return minutes
        }
        return Int(((hours ?? 0) * 60).rounded())
    }
}
