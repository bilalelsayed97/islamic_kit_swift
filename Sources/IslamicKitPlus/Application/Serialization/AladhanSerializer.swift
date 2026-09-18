/// Order of the `offset` block in aladhan `meta`.
private let offsetOrder: [Prayer] = [.imsak, .fajr, .sunrise, .dhuhr, .asr, .sunset, .maghrib, .isha, .midnight]

/// Emits whole doubles as ints (18.0 -> 18) and keeps fractional ones (18.5).
private func numFmt(_ v: Double) -> JSONValue {
    Int(exactly: v).map { .int($0) } ?? .double(v)
}

private func paramsJson(_ p: MethodParams, moonsighting: Bool, shafaq: Shafaq) -> JSONValue {
    if moonsighting { return ["shafaq": .string(shafaq.code)] }
    var out: JSONObject = ["Fajr": numFmt(p.fajrAngle)]
    if let minutes = p.ishaMinutesAfterMaghrib {
        out["Isha"] = .string("\(minutes) min")
    } else if let angle = p.ishaAngle {
        out["Isha"] = numFmt(angle)
    }
    if let angle = p.maghribAngle {
        out["Maghrib"] = numFmt(angle)
    } else if let minutes = p.maghribMinutesAfterSunset {
        out["Maghrib"] = .string("\(minutes) min")
    }
    if p.midnightMode == .jafari { out["Midnight"] = "JAFARI" }
    return .object(out)
}

private func locationJson(_ loc: Coordinates) -> JSONValue {
    ["latitude": .double(loc.latitude), "longitude": .double(loc.longitude)]
}

private func methodJson(_ m: CalculationMeta) -> JSONValue {
    let method = m.method
    var json: JSONObject = [
        "id": .int(method.id),
        "name": .string(method.methodName),
        "params": paramsJson(m.methodParams, moonsighting: method.usesMoonsighting, shafaq: m.shafaq),
    ]
    if let loc = m.methodParams.location {
        json["location"] = locationJson(loc)
    }
    return .object(json)
}

private func metaJson(_ m: CalculationMeta) -> JSONValue {
    var offset = JSONObject()
    for p in offsetOrder { offset[p.key] = .int(m.offsets[p] ?? 0) }
    return [
        "latitude": .double(m.coordinates.latitude),
        "longitude": .double(m.coordinates.longitude),
        "timezone": .string(m.timezone),
        "method": methodJson(m),
        "latitudeAdjustmentMethod": .string(m.method.usesMoonsighting ? "NONE" : m.latitudeAdjustmentMethod.metaValue),
        "midnightMode": .string(m.midnightMode.metaValue),
        "school": .string(m.school.metaValue),
        "offset": .object(offset),
    ]
}

private func gregorianJson(_ g: GregorianDate) -> JSONValue {
    [
        "date": .string(g.formatted),
        "format": "DD-MM-YYYY",
        "day": .string(StringHelpers.two(g.day)),
        "weekday": ["en": .string(g.weekdayEn)],
        "month": ["number": .int(g.month), "en": .string(g.monthEn)],
        "year": .string("\(g.year)"),
        "designation": ["abbreviated": "AD", "expanded": "Anno Domini"],
        "lunarSighting": false,
    ]
}

private func hijriJson(_ h: HijriDate) -> JSONValue {
    [
        "date": .string(h.formatted),
        "format": "DD-MM-YYYY",
        "day": .string("\(h.day)"),
        "weekday": ["en": .string(h.weekdayEn), "ar": .string(h.weekdayAr)],
        "month": [
            "number": .int(h.month),
            "en": .string(h.monthEn),
            "ar": .string(h.monthAr),
            "days": .int(h.monthLength),
        ],
        "year": .string("\(h.year)"),
        "designation": ["abbreviated": "AH", "expanded": "Anno Hegirae"],
        "holidays": .array(h.holidays.map { .string($0) }),
        "adjustedHolidays": [],
        "method": .string(h.method.code),
    ]
}

private func dateJson(_ d: DateInfo) -> JSONValue {
    [
        "readable": .string(d.readable),
        "timestamp": .string("\(d.timestamp)"),
        "hijri": hijriJson(d.hijri),
        "gregorian": gregorianJson(d.gregorian),
    ]
}

private func timingsJson(_ r: PrayerResult, _ format: TimeFormat, _ calendar: Bool) -> JSONValue {
    let suffix = calendar && format != .iso8601 && format != .float ? " (\(r.meta.timezone))" : ""
    var out = JSONObject()
    for entry in r.timings.raw.entries {
        out[entry.prayer.key] = .string("\(r.timings.formatted(entry.prayer, format))\(suffix)")
    }
    return .object(out)
}

private func envelope(_ data: JSONValue) -> JSONObject {
    ["code": 200, "status": "OK", "data": data]
}

/// aladhan-compatible serialization for a single-day `PrayerResult`.
extension PrayerResult {
    /// The `data` object: `{timings, date, meta}`. When `calendar` is true,
    /// clock-formatted timings carry the ` (timezone)` suffix aladhan uses.
    public func toAladhanData(format: TimeFormat = .h24, calendar: Bool = false) -> JSONObject {
        [
            "timings": timingsJson(self, format, calendar),
            "date": dateJson(date),
            "meta": metaJson(meta),
        ]
    }

    /// The full envelope: `{code, status, data}`.
    public func toAladhanJson(format: TimeFormat = .h24) -> JSONObject {
        envelope(.object(toAladhanData(format: format)))
    }
}

/// aladhan-compatible `/methods` response, built from `CalculationMethod`
/// (declaration order; `custom` last, without params).
public func methodsAladhanJson() -> JSONObject {
    var data = JSONObject()
    for m in CalculationMethod.allCases {
        if m == .custom {
            data[m.code] = ["id": .int(m.id), "name": .string(m.methodName)]
            continue
        }
        var entry: JSONObject = [
            "id": .int(m.id),
            "name": .string(m.methodName),
            "params": paramsJson(m.params, moonsighting: m.usesMoonsighting, shafaq: .general),
        ]
        if let loc = m.params.location {
            entry["location"] = locationJson(loc)
        }
        data[m.code] = .object(entry)
    }
    return envelope(.object(data))
}

/// aladhan-compatible calendar response: `data` is an array of day objects.
public func calendarAladhanJson(_ days: [PrayerResult], format: TimeFormat = .h24) -> JSONObject {
    envelope(.array(days.map { .object($0.toAladhanData(format: format, calendar: true)) }))
}

/// aladhan-compatible annual calendar: `data` is a map keyed by month "1".."12".
public func annualCalendarAladhanJson(_ months: [Int: [PrayerResult]], format: TimeFormat = .h24) -> JSONObject {
    var data = JSONObject()
    for m in 1...12 {
        guard let days = months[m] else { continue }
        data["\(m)"] = .array(days.map { .object($0.toAladhanData(format: format, calendar: true)) })
    }
    return envelope(.object(data))
}

/// aladhan-compatible next-prayer response: a `data` object whose `timings`
/// holds a single entry.
public func nextPrayerAladhanJson(_ dayResult: PrayerResult, _ prayer: Prayer, format: TimeFormat = .h24) -> JSONObject {
    var data = dayResult.toAladhanData(format: format)
    var single = JSONObject()
    single[prayer.key] = .string(dayResult.timings.formatted(prayer, format))
    data["timings"] = .object(single)
    return envelope(.object(data))
}

/// aladhan-compatible qibla response.
public func qiblaAladhanJson(_ q: QiblaDirection) -> JSONObject {
    envelope([
        "latitude": .double(q.from.latitude),
        "longitude": .double(q.from.longitude),
        "direction": .double(q.degrees),
    ])
}
