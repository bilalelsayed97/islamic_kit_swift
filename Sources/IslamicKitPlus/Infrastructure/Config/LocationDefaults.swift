/// Recommended calculation defaults per country, keyed by ISO-3166 alpha-2
/// code. Countries not listed fall back to the Muslim World League method,
/// which is the common default across Europe and much of the world.
///
/// This is the fallback for when the bundled city database is not open. When
/// it is, prefer the database's own `calc_method` column — see
/// `BundledMethodMap` and `PrayerTimesService.autoParamsForCoordinates`; it
/// covers all 251 countries rather than the subset listed here, and the two
/// agree wherever both have an opinion.
public enum LocationDefaults {
    private static let methodByCountry: [String: CalculationMethod] = [
        // North America
        "US": .isna,
        "CA": .canada,
        "MX": .isna,
        // Gulf / Arabian Peninsula
        "SA": .makkah,
        "AE": .dubai,
        "KW": .kuwait,
        "QA": .qatar,
        "BH": .makkah,
        "OM": .oman,
        "YE": .makkah,
        // Levant / North & East Africa
        "EG": .egypt,
        "NG": .egypt,
        "SD": .sudan,
        "SS": .sudan,
        "SY": .makkah,
        "IQ": .iraq,
        "LY": .libya,
        "JO": .jordan,
        "DZ": .algeria,
        "MA": .morocco,
        "EH": .morocco,
        "TN": .tunisia,
        // Iran / Turkey / Russia / Central Asia
        "IR": .tehran,
        "TR": .turkey,
        "RU": .russia,
        "TJ": .tajikistan,
        // South Asia
        "PK": .karachi,
        "IN": .karachi,
        "BD": .karachi,
        "AF": .karachi,
        "MV": .maldives,
        // South-East Asia
        "ID": .singapore,
        "MY": .singapore,
        "SG": .singapore,
        "BN": .jakim,
        "VN": .makkah,
        // Europe with dedicated authorities
        "FR": .france,
        "MF": .france,
        "PT": .portugal,
        "DE": .munich,
        "AT": .vienna,
        "BE": .belgium,
        "LU": .luxembourg,
    ]

    /// Countries where the Hanafi Asr shadow (factor 2) is the common default.
    private static let hanafiDefault: Set<String> = ["PK", "IN", "BD", "AF", "TR"]

    /// The recommended `CalculationMethod` for `countryCode` (falls back to MWL).
    public static func methodForCountry(_ countryCode: String) -> CalculationMethod {
        methodByCountry[countryCode.uppercased()] ?? .mwl
    }

    /// The recommended `AsrSchool` for `countryCode` (falls back to Standard).
    public static func schoolForCountry(_ countryCode: String) -> AsrSchool {
        hanafiDefault.contains(countryCode.uppercased()) ? .hanafi : .standard
    }
}
