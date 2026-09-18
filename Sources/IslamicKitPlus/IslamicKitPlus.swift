// IslamicKitPlus — offline, dependency-free Islamic prayer times, Hijri
// calendar, qibla and calendars for Swift.
//
// Prayer times are solved from Jean Meeus' solar position with three-point
// interpolation, alongside a Hijri calendar with four methods, qibla,
// calendars, an aladhan.com-compatible JSON model and English/Arabic
// localization. Everything is computed locally — no network, no runtime
// dependencies beyond Foundation.
//
// This is a behavioural port of the Dart package `islamic_kit_plus`; every
// number, string and fallback is meant to match it exactly.

/// Package-level metadata.
public enum IslamicKitPlus {
    /// The Dart engine version this port reproduces (major.minor) with an
    /// independent patch component.
    public static let version = "0.3.0"
}
