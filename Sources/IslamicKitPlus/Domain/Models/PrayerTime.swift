import Foundation

/// A single computed prayer time.
///
/// `hours` is the raw fractional-hours value in the *local* (offset-adjusted)
/// day. It may be negative or exceed 24 when the event rolls into the previous
/// or next calendar day; formatting and `instant` handle the wrap. A `nil` (or
/// NaN) `hours` means the time is invalid for the given latitude.
public struct PrayerTime: Hashable, Sendable, CustomStringConvertible {
    public let prayer: Prayer
    public let hours: Double?

    /// The civil calendar date the times were computed for.
    public let date: CivilDate

    /// The UTC offset used to localize the times.
    public let utcOffset: UTCOffset

    public init(prayer: Prayer, hours: Double?, date: CivilDate, utcOffset: UTCOffset) {
        self.prayer = prayer
        self.hours = hours
        self.date = date
        self.utcOffset = utcOffset
    }

    public var isValid: Bool {
        guard let hours = hours else { return false }
        return !hours.isNaN
    }

    /// Localized display name of the prayer.
    public func name(_ language: Language) -> String { prayer.localizedName(language) }

    /// Formats the time using `format` (defaults to 24-hour).
    public func format(_ format: TimeFormat = .h24) -> String {
        formatHours(hours, format, date, utcOffset)
    }

    /// Milliseconds since the Unix epoch of the absolute instant, or `nil` if
    /// invalid (Dart `toUtc().millisecondsSinceEpoch`).
    public var epochMilliseconds: Int? {
        guard isValid, let hours = hours else { return nil }
        let wall = date.unixMidnightSeconds * 1000 + Int((hours * 3_600_000).rounded())
        return wall - utcOffset.seconds * 1000
    }

    /// The absolute instant as a Foundation `Date`, or `nil` if invalid.
    public var instant: Date? {
        epochMilliseconds.map { Date(timeIntervalSince1970: Double($0) / 1000) }
    }

    public var description: String { "\(prayer.key): \(format())" }
}

/// Raw fractional-hours per prayer, stored as an 11-slot array indexed by
/// `Prayer` ordinal so that enum order and `nil` semantics are exact.
public struct RawPrayerTimes: Hashable, Sendable {
    private var storage: [Double?]

    /// Every prayer invalid (the polar day/night result).
    public static let allInvalid = RawPrayerTimes()

    /// All slots `nil`.
    public init() {
        storage = Array(repeating: nil, count: Prayer.allCases.count)
    }

    /// Builds the table by asking `hours` for every prayer in enum order.
    public init(_ hours: (Prayer) -> Double?) {
        storage = Prayer.allCases.map(hours)
    }

    /// Builds the table from a map (missing prayers are `nil`).
    public init(_ values: [Prayer: Double?]) {
        self.init { values[$0] ?? nil }
    }

    public subscript(prayer: Prayer) -> Double? {
        get { storage[prayer.ordinal] }
        set { storage[prayer.ordinal] = newValue }
    }

    /// `(prayer, hours)` pairs in `Prayer` declaration order.
    public var entries: [(prayer: Prayer, hours: Double?)] {
        Prayer.allCases.map { ($0, storage[$0.ordinal]) }
    }
}

extension RawPrayerTimes: Sequence {
    public func makeIterator() -> IndexingIterator<[(prayer: Prayer, hours: Double?)]> {
        entries.makeIterator()
    }
}

/// The full set of computed times for a single date and location.
public struct PrayerTimings: Hashable, Sendable {
    /// Raw fractional-hours per prayer (nil/NaN = invalid).
    public let raw: RawPrayerTimes

    /// The civil calendar date the times were computed for.
    public let date: CivilDate

    /// The UTC offset used to localize the times.
    public let utcOffset: UTCOffset

    public init(raw: RawPrayerTimes, date: CivilDate, utcOffset: UTCOffset) {
        self.raw = raw
        self.date = date
        self.utcOffset = utcOffset
    }

    /// Returns the `PrayerTime` for `prayer`.
    public func time(_ prayer: Prayer) -> PrayerTime {
        PrayerTime(prayer: prayer, hours: raw[prayer], date: date, utcOffset: utcOffset)
    }

    /// Formats a single prayer.
    public func formatted(_ prayer: Prayer, _ format: TimeFormat = .h24) -> String {
        time(prayer).format(format)
    }

    /// Every prayer to its formatted string.
    public func toFormattedMap(_ format: TimeFormat = .h24) -> [Prayer: String] {
        var out = [Prayer: String]()
        for prayer in Prayer.allCases { out[prayer] = formatted(prayer, format) }
        return out
    }
}
