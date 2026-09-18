/// Sentinel returned when a time cannot be computed (e.g. sun never reaches the
/// required angle at extreme latitudes). Matches the PHP `INVALID_TIME`.
public let invalidTime = "-----"

/// Positive-modulo wrap to the range `[0, 24)`.
public func fixHour(_ a: Double) -> Double {
    let r = a - 24 * (a / 24).rounded(.down)
    return r < 0 ? r + 24 : r
}

/// Formats a raw fractional-hours value using `format`.
///
/// Faithful port of `PrayerTimes::getFormattedTime`: adds 0.5 minutes for
/// rounding before truncating clock formats; the ISO-8601 path uses the raw
/// (pre-rounding) value offset from midnight of `date` and appends
/// `utcOffset`. The ISO path is pure civil-date arithmetic, so no host time
/// zone can leak into the day rollover.
public func formatHours(
    _ hours: Double?,
    _ format: TimeFormat,
    _ date: CivilDate,
    _ utcOffset: UTCOffset
) -> String {
    guard let hours = hours, !hours.isNaN else { return invalidTime }
    if format == .float { return DartNumberFormatting.string(hours) }

    // 0.5-minute rounding, applied before truncation for every non-float format
    // (including ISO-8601), matching the PHP original.
    let t = hours + 0.5 / 60

    if format == .iso8601 {
        let totalMinutes = t > 0 ? Int((t * 60).rounded(.down)) : -Int((-t * 60).rounded(.up))
        let dayOffset = IntegerMath.floorDiv(totalMinutes, 1440)
        let minuteOfDay = IntegerMath.floorMod(totalMinutes, 1440)
        let day = date.addingDays(dayOffset)
        let stamp = "\(StringHelpers.padLeft4(day.year))-\(StringHelpers.two(day.month))-"
            + "\(StringHelpers.two(day.day))T\(StringHelpers.two(minuteOfDay / 60)):"
            + "\(StringHelpers.two(minuteOfDay % 60)):00"
        return "\(stamp)\(utcOffset.isoString)"
    }

    let ft = fixHour(t)
    let h = Int(ft.rounded(.down))
    let m = Int(((ft - Double(h)) * 60).rounded(.down))
    if format == .h24 { return "\(StringHelpers.two(h)):\(StringHelpers.two(m))" }

    let hour12 = (h + 12 - 1) % 12 + 1
    let body = "\(hour12):\(StringHelpers.two(m))"
    if format == .h12 { return "\(body) \(h < 12 ? "am" : "pm")" }
    return body // h12NoSuffix
}
