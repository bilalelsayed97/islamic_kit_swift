import Foundation

/// A civil date with a wall-clock time (no time zone), used to ask for the
/// next prayer after a given local instant.
public struct CivilDateTime: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let date: CivilDate
    public let hour: Int
    public let minute: Int
    public let second: Int

    public init(date: CivilDate, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        self.date = date
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        self.init(date: CivilDate(year: year, month: month, day: day), hour: hour, minute: minute, second: second)
    }

    /// Fractional hours since midnight (`hour + minute/60 + second/3600`).
    public var fractionalHours: Double {
        Double(hour) + Double(minute) / 60 + Double(second) / 3600
    }

    /// `yyyy-mm-ddThh:mm:ss`.
    public var isoString: String {
        "\(date.isoString)T\(StringHelpers.two(hour)):\(StringHelpers.two(minute)):\(StringHelpers.two(second))"
    }

    public var description: String { isoString }

    public static func < (lhs: CivilDateTime, rhs: CivilDateTime) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
        if lhs.minute != rhs.minute { return lhs.minute < rhs.minute }
        return lhs.second < rhs.second
    }

    // MARK: Foundation conveniences

    /// The wall-clock time of `date` as seen in `timeZone`.
    public init(_ date: Date, in timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        self.init(year: c.year!, month: c.month!, day: c.day!, hour: c.hour!, minute: c.minute!, second: c.second!)
    }

    /// The current wall-clock time in `timeZone`.
    public static func now(in timeZone: TimeZone = .current) -> CivilDateTime {
        CivilDateTime(Date(), in: timeZone)
    }
}
