/// Strongly-typed twilight parameters for a calculation method.
///
/// Isha and Maghrib can each be defined either as an angle **or** as a number
/// of minutes after the preceding event. `adjustments` carries the whole-minute
/// corrections the authority publishes on top of the astronomy.
public struct MethodParams: Hashable, Sendable {
    /// Fajr twilight angle in degrees below the horizon.
    public var fajrAngle: Double

    /// Isha twilight angle in degrees, if defined by angle.
    public var ishaAngle: Double?

    /// Minutes after Maghrib for Isha, if defined by a fixed interval.
    public var ishaMinutesAfterMaghrib: Int?

    /// Interval used instead of `ishaMinutesAfterMaghrib` during Ramadan.
    ///
    /// Umm al-Qura lengthens its 90-minute interval to 120 minutes for the
    /// month; no other method varies by season.
    public var ramadanIshaMinutesAfterMaghrib: Int?

    /// Maghrib angle in degrees, if defined by angle (rare; e.g. Jafari/Tehran).
    public var maghribAngle: Double?

    /// Minutes after Sunset for Maghrib, if defined by a fixed interval.
    public var maghribMinutesAfterSunset: Int?

    /// Whole-minute corrections the method applies to its own times.
    public var adjustments: MethodAdjustments

    /// Midnight mode implied by the method (e.g. Jafari for Shia methods).
    public var midnightMode: MidnightMode?

    /// Reference location associated with the method (informational).
    public var location: Coordinates?

    public init(
        fajrAngle: Double = 0,
        ishaAngle: Double? = nil,
        ishaMinutesAfterMaghrib: Int? = nil,
        ramadanIshaMinutesAfterMaghrib: Int? = nil,
        maghribAngle: Double? = nil,
        maghribMinutesAfterSunset: Int? = nil,
        adjustments: MethodAdjustments = .none,
        midnightMode: MidnightMode? = nil,
        location: Coordinates? = nil
    ) {
        self.fajrAngle = fajrAngle
        self.ishaAngle = ishaAngle
        self.ishaMinutesAfterMaghrib = ishaMinutesAfterMaghrib
        self.ramadanIshaMinutesAfterMaghrib = ramadanIshaMinutesAfterMaghrib
        self.maghribAngle = maghribAngle
        self.maghribMinutesAfterSunset = maghribMinutesAfterSunset
        self.adjustments = adjustments
        self.midnightMode = midnightMode
        self.location = location
    }

    /// Whether Isha is defined as a fixed number of minutes after Maghrib.
    public var ishaIsInterval: Bool { ishaMinutesAfterMaghrib != nil }

    /// Whether Maghrib is defined as a fixed number of minutes after Sunset.
    public var maghribIsInterval: Bool { maghribMinutesAfterSunset != nil }

    /// Whether the Isha interval changes during Ramadan.
    public var hasRamadanIshaInterval: Bool { ramadanIshaMinutesAfterMaghrib != nil }

    /// These params with the Ramadan Isha interval applied, when the method
    /// defines one. Returns `self` unchanged otherwise.
    public func forRamadan() -> MethodParams {
        guard let ramadan = ramadanIshaMinutesAfterMaghrib else { return self }
        var copy = self
        copy.ishaMinutesAfterMaghrib = ramadan
        return copy
    }
}
