/// The Hijri calendar calculation method used for Gregorian <-> Hijri
/// conversion.
public enum CalendarMethod: String, CaseIterable, Sendable {
    /// High Judicial Council of Saudi Arabia (Umm al-Qura table + announced
    /// lunar-sighting overrides). This is the aladhan.com default.
    case hjcosa = "HJCoSA"

    /// Umm al-Qura (table lookup).
    case uaq = "UAQ"

    /// Diyanet İşleri Başkanlığı (table lookup).
    case diyanet = "DIYANET"

    /// Pure arithmetic (tabular) calendar; supports a day adjustment.
    case mathematical = "MATHEMATICAL"

    /// The aladhan `calendarMethod` identifier.
    public var code: String { rawValue }

    /// Looks a method up by code, falling back to `.hjcosa`.
    public static func fromCode(_ code: String) -> CalendarMethod {
        allCases.first { $0.code == code } ?? .hjcosa
    }
}
