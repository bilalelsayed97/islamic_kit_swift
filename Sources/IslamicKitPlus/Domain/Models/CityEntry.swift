/// A city row from the bundled city database, with its country resolved.
///
/// This is the richer sibling of `City`: it keeps the database identifiers and
/// both localized name pairs, which a city-picker UI needs and a geocoding
/// result does not. Equality and hashing are by `id` alone.
public struct CityEntry: Hashable, Sendable, CustomStringConvertible {
    /// Primary key in the bundled database (`prayer_times_city_lookups`).
    public let id: Int

    /// English city name.
    public let nameEn: String

    /// Arabic city name.
    public let nameAr: String

    /// Owning country's primary key.
    public let countryId: Int

    /// English country name.
    public let countryNameEn: String

    /// Arabic country name.
    public let countryNameAr: String

    /// ISO 3166-1 alpha-2 code of the owning country. Empty when unmapped.
    public let isoCode: String

    public let coordinates: Coordinates

    /// IANA timezone identifier, e.g. `"Africa/Cairo"`. `nil` when unknown.
    public let timeZoneId: String?

    /// Standard-time UTC offset. Does **not** account for daylight saving.
    public let utcOffset: UTCOffset

    /// Raw `calc_method` value the database recommends for this city's country.
    ///
    /// The database's own numbering, **not** an aladhan method id. Resolve it
    /// with `BundledMethodMap` (or the `calculationMethod` property).
    public let calculationMethodId: Int?

    public init(
        id: Int,
        nameEn: String,
        nameAr: String,
        countryId: Int,
        countryNameEn: String,
        countryNameAr: String,
        isoCode: String,
        coordinates: Coordinates,
        utcOffset: UTCOffset,
        timeZoneId: String? = nil,
        calculationMethodId: Int? = nil
    ) {
        self.id = id
        self.nameEn = nameEn
        self.nameAr = nameAr
        self.countryId = countryId
        self.countryNameEn = countryNameEn
        self.countryNameAr = countryNameAr
        self.isoCode = isoCode
        self.coordinates = coordinates
        self.timeZoneId = timeZoneId
        self.utcOffset = utcOffset
        self.calculationMethodId = calculationMethodId
    }

    public static func == (lhs: CityEntry, rhs: CityEntry) -> Bool { lhs.id == rhs.id }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    public var description: String { "CityEntry(\(nameEn), \(isoCode))" }
}
