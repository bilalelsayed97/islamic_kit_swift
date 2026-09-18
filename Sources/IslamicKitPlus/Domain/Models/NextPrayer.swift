/// The next upcoming prayer relative to a given instant.
public struct NextPrayer: Hashable, Sendable {
    public let prayer: Prayer
    public let time: PrayerTime

    /// The civil date the next prayer falls on (may be the following day).
    public let onDate: CivilDate

    public init(prayer: Prayer, time: PrayerTime, onDate: CivilDate) {
        self.prayer = prayer
        self.time = time
        self.onDate = onDate
    }
}
