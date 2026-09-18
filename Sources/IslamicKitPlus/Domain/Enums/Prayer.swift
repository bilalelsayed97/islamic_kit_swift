/// The prayers and derived times the library computes.
///
/// `key` is the canonical identifier used in the aladhan-compatible JSON model
/// (e.g. `"Fajr"`). Cases are declared in the Dart package's order, which is
/// also the order `RawPrayerTimes` and the aladhan `timings` block iterate in.
public enum Prayer: String, CaseIterable, Sendable {
    case imsak = "Imsak"
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case sunset = "Sunset"
    case maghrib = "Maghrib"
    case isha = "Isha"
    case midnight = "Midnight"
    case firstThird = "Firstthird"
    case lastThird = "Lastthird"

    /// Canonical aladhan JSON key, e.g. `"Fajr"`.
    public var key: String { rawValue }

    /// English display name.
    public var nameEn: String {
        switch self {
        case .firstThird: return "First Third"
        case .lastThird: return "Last Third"
        default: return rawValue
        }
    }

    /// Arabic display name.
    public var nameAr: String { title(.ar) }

    /// Localized display name for `language`.
    public func localizedName(_ language: Language) -> String {
        language == .ar ? nameAr : nameEn
    }

    /// Looks a prayer up by its aladhan key (`nil` when unknown; the Dart
    /// `Prayer.fromKey` throws an `ArgumentError` instead).
    public init?(key: String) {
        self.init(rawValue: key)
    }

    /// Position in the Dart declaration order (0 = imsak … 10 = lastThird).
    public var ordinal: Int {
        Prayer.allCases.firstIndex(of: self)!
    }

    /// The five obligatory daily prayers, in chronological order.
    ///
    /// Used to determine the next prayer.
    public static let dailyObligatory: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
}
