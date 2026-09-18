/// The combined date block returned with each result: a human-readable label,
/// a Unix timestamp, and both the Gregorian and Hijri representations.
public struct DateInfo: Hashable, Sendable {
    /// e.g. `"01 Jan 2025"`.
    public let readable: String

    /// Unix timestamp (seconds) of the civil date at the used UTC offset.
    public let timestamp: Int

    public let gregorian: GregorianDate
    public let hijri: HijriDate

    public init(readable: String, timestamp: Int, gregorian: GregorianDate, hijri: HijriDate) {
        self.readable = readable
        self.timestamp = timestamp
        self.gregorian = gregorian
        self.hijri = hijri
    }
}
