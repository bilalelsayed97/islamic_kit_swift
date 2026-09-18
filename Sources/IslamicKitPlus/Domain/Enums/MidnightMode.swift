/// How the Midnight (and the night thirds) are anchored.
public enum MidnightMode: Int, CaseIterable, Sendable {
    /// Midpoint of Sunset to Sunrise.
    case standard = 0

    /// Midpoint of Sunset to Fajr (Shia / Jafari).
    case jafari = 1

    /// Integer value accepted by the aladhan `midnightMode` query parameter.
    public var aladhanId: Int { rawValue }

    /// String value echoed in the aladhan `meta.midnightMode` field.
    public var metaValue: String {
        switch self {
        case .standard: return "STANDARD"
        case .jafari: return "JAFARI"
        }
    }

    /// Looks a mode up by aladhan id, falling back to `.standard`.
    public static func fromAladhanId(_ id: Int) -> MidnightMode {
        allCases.first { $0.aladhanId == id } ?? .standard
    }
}
