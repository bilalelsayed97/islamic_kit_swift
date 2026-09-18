/// Adjustment applied to Fajr/Isha/Imsak/Maghrib at high latitudes where the
/// sun may not reach the required twilight angle.
public enum HighLatitudeRule: Int, CaseIterable, Sendable {
    /// No adjustment.
    case none = 0

    /// The night is split in half (middle of the night).
    case middleOfNight = 1

    /// One-seventh of the night.
    case oneSeventh = 2

    /// A portion of the night proportional to the twilight angle (angle / 60).
    case angleBased = 3

    /// Integer value accepted by the aladhan `latitudeAdjustmentMethod`
    /// parameter. (`none` has no aladhan integer; it is represented as `0`.)
    public var aladhanId: Int { rawValue }

    /// String value echoed in the aladhan `meta.latitudeAdjustmentMethod` field.
    public var metaValue: String {
        switch self {
        case .none: return "NONE"
        case .middleOfNight: return "MIDDLE_OF_THE_NIGHT"
        case .oneSeventh: return "ONE_SEVENTH"
        case .angleBased: return "ANGLE_BASED"
        }
    }

    /// Looks a rule up by aladhan id, falling back to `.angleBased`.
    public static func fromAladhanId(_ id: Int) -> HighLatitudeRule {
        allCases.first { $0.aladhanId == id } ?? .angleBased
    }
}
