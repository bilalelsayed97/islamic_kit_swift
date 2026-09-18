/// Browsable, localized view over the bundled city database.
///
/// A `Geocoder` answers "which city is this text?"; a `CityDirectory` answers
/// the questions a location-picker asks instead — list the countries, page
/// through a country's cities, resolve GPS coordinates to a city, and offer
/// the timezones a country actually spans. The core library only defines the
/// port; `IslamicKitPlusGeocoding` ships `SqliteCityDirectory`.
public protocol CityDirectory: Sendable {
    /// Every country that has at least one populated place, ordered by English
    /// name. `query` filters on either name, case-insensitively.
    func countries(query: String?) -> [CountryInfo]

    /// The country with `countryId`, or `nil` when no such row exists.
    func country(_ countryId: Int) -> CountryInfo?

    /// Populated places inside `countryId`, most prominent first. `query`
    /// filters on either name; `limit` and `offset` page.
    func citiesInCountry(_ countryId: Int, query: String?, limit: Int, offset: Int) -> [CityEntry]

    /// Populated places anywhere, most prominent first.
    func searchCities(query: String?, limit: Int, offset: Int) -> [CityEntry]

    /// The city `latitude`/`longitude` most plausibly names (prominence-weighted
    /// proximity), or `nil` when the database is empty.
    func nearestCity(_ latitude: Double, _ longitude: Double) -> CityEntry?

    /// The timezones `countryId` actually spans, ordered by IANA id.
    func timeZonesForCountry(_ countryId: Int) -> [TimeZoneInfo]
}

extension CityDirectory {
    /// All countries, unfiltered.
    public func countries() -> [CountryInfo] {
        countries(query: nil)
    }

    /// `citiesInCountry` with the Dart defaults (`limit: 50, offset: 0`).
    public func citiesInCountry(_ countryId: Int, query: String? = nil, limit: Int = 50) -> [CityEntry] {
        citiesInCountry(countryId, query: query, limit: limit, offset: 0)
    }

    /// `searchCities` with the Dart defaults (`limit: 50, offset: 0`).
    public func searchCities(query: String? = nil, limit: Int = 50) -> [CityEntry] {
        searchCities(query: query, limit: limit, offset: 0)
    }
}
