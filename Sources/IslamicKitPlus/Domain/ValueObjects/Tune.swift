/// Per-prayer time adjustments, in minutes — the equivalent of the aladhan
/// `tune` parameter.
///
/// Field order matches the aladhan contract exactly:
/// `Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, Isha, Midnight`
/// (note Maghrib comes before Sunset). Each value defaults to `0`.
public struct Tune: Hashable, Sendable {
    /// No adjustments.
    public static let none = Tune()

    public var imsak: Int
    public var fajr: Int
    public var sunrise: Int
    public var dhuhr: Int
    public var asr: Int
    public var maghrib: Int
    public var sunset: Int
    public var isha: Int
    public var midnight: Int

    public init(
        imsak: Int = 0,
        fajr: Int = 0,
        sunrise: Int = 0,
        dhuhr: Int = 0,
        asr: Int = 0,
        maghrib: Int = 0,
        sunset: Int = 0,
        isha: Int = 0,
        midnight: Int = 0
    ) {
        self.imsak = imsak
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.sunset = sunset
        self.isha = isha
        self.midnight = midnight
    }

    /// Parses an aladhan `tune` CSV string, e.g. `"5,3,5,7,9,-1,0,8,-6"`.
    /// Missing trailing values default to `0`; unparsable values become `0`.
    public init(csv: String) {
        let parts = csv.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        func at(_ i: Int) -> Int {
            i < parts.count ? (Int(StringHelpers.dartTrim(parts[i])) ?? 0) : 0
        }
        self.init(
            imsak: at(0),
            fajr: at(1),
            sunrise: at(2),
            dhuhr: at(3),
            asr: at(4),
            maghrib: at(5),
            sunset: at(6),
            isha: at(7),
            midnight: at(8)
        )
    }

    /// Whether every adjustment is zero.
    public var isEmpty: Bool {
        imsak == 0 && fajr == 0 && sunrise == 0 && dhuhr == 0 && asr == 0
            && maghrib == 0 && sunset == 0 && isha == 0 && midnight == 0
    }

    /// The aladhan `tune` CSV, e.g. `"5,3,5,7,9,-1,0,8,-6"`.
    public var csv: String {
        "\(imsak),\(fajr),\(sunrise),\(dhuhr),\(asr),\(maghrib),\(sunset),\(isha),\(midnight)"
    }

    /// A map keyed by `Prayer` (the nine prayers aladhan's `offset` block
    /// carries; the night thirds are never tuned).
    public func toMap() -> [Prayer: Int] {
        [
            .imsak: imsak,
            .fajr: fajr,
            .sunrise: sunrise,
            .dhuhr: dhuhr,
            .asr: asr,
            .sunset: sunset,
            .maghrib: maghrib,
            .isha: isha,
            .midnight: midnight,
        ]
    }

    /// Equality is defined by the CSV form, as in the Dart package.
    public static func == (lhs: Tune, rhs: Tune) -> Bool {
        lhs.csv == rhs.csv
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(csv)
    }
}
