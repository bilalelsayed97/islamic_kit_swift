/// A country row from the bundled city database.
///
/// Country names ship in both English and Arabic, so a caller can render the
/// active locale without a second lookup. Equality and hashing are by `id`.
public struct CountryInfo: Hashable, Sendable, CustomStringConvertible {
    /// Primary key in the bundled database (`prayer_times_country_lookups`).
    public let id: Int

    /// English country name, e.g. `"Egypt"`.
    public let nameEn: String

    /// Arabic country name, e.g. `"مصر"`.
    public let nameAr: String

    /// ISO 3166-1 alpha-2 code, e.g. `"EG"`. Empty when the id is unmapped.
    public let isoCode: String

    /// Raw `calc_method` value the database recommends for this country.
    ///
    /// This is the database's own numbering, **not** an aladhan method id — the
    /// two collide above 5. Resolve it with `BundledMethodMap` (or the
    /// `calculationMethod` property) rather than interpreting it.
    public let calculationMethodId: Int?

    public init(id: Int, nameEn: String, nameAr: String, isoCode: String, calculationMethodId: Int? = nil) {
        self.id = id
        self.nameEn = nameEn
        self.nameAr = nameAr
        self.isoCode = isoCode
        self.calculationMethodId = calculationMethodId
    }

    public static func == (lhs: CountryInfo, rhs: CountryInfo) -> Bool { lhs.id == rhs.id }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    public var description: String { "CountryInfo(\(nameEn), \(isoCode))" }
}
