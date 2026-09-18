/// Output format for a computed time.
public enum TimeFormat: String, CaseIterable, Sendable {
    /// 24-hour clock, e.g. `03:57`.
    case h24 = "24h"

    /// 12-hour clock with am/pm suffix, e.g. `3:57 am`.
    case h12 = "12h"

    /// 12-hour clock without a suffix, e.g. `3:57`.
    case h12NoSuffix = "12hNS"

    /// Raw floating-point hours (0..24), e.g. `3.95`.
    case float = "Float"

    /// ISO-8601 with timezone offset, e.g. `2014-04-24T03:57:00+01:00`.
    case iso8601 = "iso8601"

    /// The aladhan format identifier.
    public var code: String { rawValue }
}
