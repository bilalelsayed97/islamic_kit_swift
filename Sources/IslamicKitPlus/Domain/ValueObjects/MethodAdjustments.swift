/// Whole-minute corrections a calculation method applies to its own output.
///
/// These are part of the *method's definition* — several authorities publish
/// times that sit a minute or two off the pure astronomical value (most add a
/// minute to Dhuhr so the printed time is safely past the zenith). They are
/// applied on top of the astronomy and before rounding, and are independent of
/// the user's own `tune` offsets, which apply afterwards.
public struct MethodAdjustments: Hashable, Sendable {
    /// No corrections — the astronomical values stand as computed.
    public static let none = MethodAdjustments()

    public var fajr: Int
    public var sunrise: Int
    public var dhuhr: Int
    public var asr: Int
    public var maghrib: Int
    public var isha: Int

    public init(
        fajr: Int = 0,
        sunrise: Int = 0,
        dhuhr: Int = 0,
        asr: Int = 0,
        maghrib: Int = 0,
        isha: Int = 0
    ) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }

    /// Whether every correction is zero.
    public var isEmpty: Bool {
        fajr == 0 && sunrise == 0 && dhuhr == 0 && asr == 0 && maghrib == 0 && isha == 0
    }
}
