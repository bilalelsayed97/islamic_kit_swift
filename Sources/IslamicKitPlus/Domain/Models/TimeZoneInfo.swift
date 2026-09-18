/// An IANA timezone offered for a country, with its Arabic label.
/// Equality and hashing are by `(ianaId, countryId)`.
public struct TimeZoneInfo: Hashable, Sendable, CustomStringConvertible {
    /// IANA timezone identifier, e.g. `"America/Chicago"`.
    public let ianaId: String

    /// Owning country's primary key in the bundled database.
    public let countryId: Int

    /// Arabic zone label, e.g. `"التوقيت الرسمي المركزي"`. `nil` when unknown.
    public let nameAr: String?

    public init(ianaId: String, countryId: Int, nameAr: String? = nil) {
        self.ianaId = ianaId
        self.countryId = countryId
        self.nameAr = nameAr
    }

    public static func == (lhs: TimeZoneInfo, rhs: TimeZoneInfo) -> Bool {
        lhs.ianaId == rhs.ianaId && lhs.countryId == rhs.countryId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ianaId)
        hasher.combine(countryId)
    }

    public var description: String { "TimeZoneInfo(\(ianaId))" }
}
