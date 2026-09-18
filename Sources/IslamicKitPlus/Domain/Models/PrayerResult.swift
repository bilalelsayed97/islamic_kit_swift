/// The result of a timings calculation for a single date and location.
///
/// Bundles the computed `timings`, the `date` block (Gregorian + Hijri) and the
/// `meta` echo — the same triple aladhan returns under `data`. A calendar is a
/// list of these.
public struct PrayerResult: Hashable, Sendable {
    public let timings: PrayerTimings
    public let date: DateInfo
    public let meta: CalculationMeta

    public init(timings: PrayerTimings, date: DateInfo, meta: CalculationMeta) {
        self.timings = timings
        self.date = date
        self.meta = meta
    }

    /// Shortcut to a single `PrayerTime`.
    public func time(_ prayer: Prayer) -> PrayerTime { timings.time(prayer) }

    /// Shortcut to a single formatted prayer string.
    public func formatted(_ prayer: Prayer, _ format: TimeFormat = .h24) -> String {
        timings.formatted(prayer, format)
    }
}
