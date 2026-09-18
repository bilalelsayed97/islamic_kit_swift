/// Translates the bundled database's `calc_method` column into a
/// `CalculationMethod`.
///
/// > **These ids are not aladhan ids.** The `prayer_times_country_lookups`
/// > table numbers its authorities independently, and the two schemes collide
/// > above 5 — database id 7 is Kuwait while aladhan id 7 is Tehran. Never
/// > pass a `calc_method` value to `CalculationMethod.fromId`; route it
/// > through `methodForBundledId` instead.
public enum BundledMethodMap {
    private static let byId: [Int: CalculationMethod] = [
        1: .karachi,
        2: .isna,
        3: .mwl,
        4: .makkah,
        5: .egypt,
        6: .dubai,
        7: .kuwait,
        8: .qatar,
        9: .singapore,
        10: .algeria,
        11: .france,
        12: .russia,
        13: .tunisia,
        14: .turkey,
        15: .morocco,
        16: .jordan,
        17: .oman,
        18: .munich,
        19: .maldives,
        20: .canada,
        21: .tajikistan,
        22: .vienna,
        23: .belgium,
        24: .sudan,
        25: .libya,
        26: .iraq,
        27: .luxembourg,
        28: .tehran,
        29: .moonsighting,
        30: .custom,
    ]

    /// The method for a database `calc_method` value.
    ///
    /// Returns `nil` for an unknown id so callers can decide whether to fall
    /// back; use `methodForBundledIdOrDefault` for the engine's own default.
    public static func methodForBundledId(_ id: Int?) -> CalculationMethod? {
        id.flatMap { byId[$0] }
    }

    /// As `methodForBundledId`, falling back to `.mwl` — the bucket the
    /// database itself assigns to most of the world.
    public static func methodForBundledIdOrDefault(_ id: Int?) -> CalculationMethod {
        methodForBundledId(id) ?? .mwl
    }

    /// Every database id the map understands (ascending).
    public static var knownIds: [Int] { byId.keys.sorted() }
}

extension CountryInfo {
    /// The method the database recommends, or `nil` when it records none.
    public var calculationMethod: CalculationMethod? {
        BundledMethodMap.methodForBundledId(calculationMethodId)
    }
}

extension CityEntry {
    /// The method the database recommends for this city's country, or `nil`
    /// when it records none.
    public var calculationMethod: CalculationMethod? {
        BundledMethodMap.methodForBundledId(calculationMethodId)
    }
}
