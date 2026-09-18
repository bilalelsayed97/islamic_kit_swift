/// Twilight (shafaq) definition used by the Moonsighting Committee method for
/// computing Isha.
public enum Shafaq: String, CaseIterable, Sendable {
    /// General twilight.
    case general

    /// Red twilight (shafaq al-ahmar).
    case ahmer

    /// White twilight (shafaq al-abyad).
    case abyad

    /// The aladhan `shafaq` identifier.
    public var code: String { rawValue }

    /// Looks a shafaq up by code, falling back to `.general`.
    public static func fromCode(_ code: String) -> Shafaq {
        allCases.first { $0.code == code } ?? .general
    }
}
