/// Juristic school that determines the shadow ratio used for Asr.
public enum AsrSchool: Int, CaseIterable, Sendable {
    /// Shafi'i, Maliki, Hanbali — Asr begins at shadow factor 1.
    case standard = 0

    /// Hanafi — Asr begins at shadow factor 2.
    case hanafi = 1

    /// Integer value accepted by the aladhan `school` query parameter.
    public var aladhanId: Int { rawValue }

    /// String value echoed in the aladhan `meta.school` field.
    public var metaValue: String {
        switch self {
        case .standard: return "STANDARD"
        case .hanafi: return "HANAFI"
        }
    }

    /// The Asr shadow-length multiplier.
    public var shadowFactor: Int {
        switch self {
        case .standard: return 1
        case .hanafi: return 2
        }
    }

    /// Looks a school up by aladhan id, falling back to `.standard`.
    public static func fromAladhanId(_ id: Int) -> AsrSchool {
        allCases.first { $0.aladhanId == id } ?? .standard
    }
}
