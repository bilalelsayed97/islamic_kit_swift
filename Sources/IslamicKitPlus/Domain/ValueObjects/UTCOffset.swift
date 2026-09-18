import Foundation

/// A fixed UTC offset in whole seconds (the port of Dart's `Duration utcOffset`).
///
/// The package has no timezone database, so the caller supplies the offset
/// for the target date, DST included. `TimeZone` conveniences are provided
/// for callers that do have Foundation's database at hand.
public struct UTCOffset: Hashable, Sendable, CustomStringConvertible {
    /// UTC itself.
    public static let zero = UTCOffset(seconds: 0)

    /// Total offset in seconds east of UTC (negative west).
    public let seconds: Int

    public init(seconds: Int) {
        self.seconds = seconds
    }

    /// `hours` and `minutes` are summed, so `UTCOffset(hours: -3, minutes: -30)`
    /// is `-03:30`.
    public init(hours: Int, minutes: Int = 0) {
        self.seconds = hours * 3600 + minutes * 60
    }

    /// Total offset in whole minutes (truncating toward zero).
    public var totalMinutes: Int { seconds / 60 }

    /// Whole hours (truncating toward zero), e.g. `-3` for `-03:30`.
    public var hours: Int { seconds / 3600 }

    /// The minutes component of the absolute offset, e.g. `30` for `-03:30`.
    public var minutesPart: Int { (Swift.abs(seconds) / 60) % 60 }

    /// Whether the offset lies west of UTC.
    public var isNegative: Bool { seconds < 0 }

    /// The absolute offset.
    public func abs() -> UTCOffset { UTCOffset(seconds: Swift.abs(seconds)) }

    /// `±HH:MM`, e.g. `"+05:30"`.
    public var isoString: String {
        let sign = isNegative ? "-" : "+"
        let a = abs()
        return "\(sign)\(StringHelpers.two(a.hours)):\(StringHelpers.two(a.minutesPart))"
    }

    /// Parses `±HH:MM`, `±HHMM`, `±HH` or `Z`.
    public init?(iso: String) {
        let s = iso.trimmingCharacters(in: .whitespaces)
        if s == "Z" || s == "z" { self = .zero; return }
        guard let first = s.first, first == "+" || first == "-" else { return nil }
        let body = s.dropFirst().replacingOccurrences(of: ":", with: "")
        guard body.count == 2 || body.count == 4, body.allSatisfy(\.isNumber) else { return nil }
        let h = Int(body.prefix(2))!
        let m = body.count == 4 ? Int(body.suffix(2))! : 0
        guard m < 60 else { return nil }
        let total = h * 3600 + m * 60
        self.init(seconds: first == "-" ? -total : total)
    }

    /// The offset `timeZone` observes at `date` (DST-aware).
    public init(timeZone: TimeZone, at date: Date = Date()) {
        self.init(seconds: timeZone.secondsFromGMT(for: date))
    }

    /// The offset `timeZone` observes at local noon of `civilDate`.
    public init(timeZone: TimeZone, on civilDate: CivilDate) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(
            year: civilDate.year, month: civilDate.month, day: civilDate.day, hour: 12
        )
        // A normalised civil date always has a noon in every zone.
        let noon = calendar.date(from: components)!
        self.init(seconds: timeZone.secondsFromGMT(for: noon))
    }

    public var description: String { "UTCOffset(\(isoString))" }
}
