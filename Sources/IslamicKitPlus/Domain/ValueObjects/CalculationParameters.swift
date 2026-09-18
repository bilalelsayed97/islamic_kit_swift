/// All configuration for a calculation. A value type: mutate a copy (or use
/// `with(_:)`) to derive a tweaked variant, as `copyWith` does in Dart.
///
/// The caller supplies `utcOffset` because the package has no timezone
/// database — this keeps it dependency-free. Include any DST in the offset you
/// pass for the target date.
public struct CalculationParameters: Hashable, Sendable {
    public var method: CalculationMethod

    /// Params used when `method` is `.custom`.
    public var customMethod: MethodParams?

    public var school: AsrSchool

    /// Overrides the school's Asr shadow factor when non-nil.
    public var asrShadowFactor: Double?

    /// Overrides the method's implied midnight mode when non-nil.
    public var midnightMode: MidnightMode?

    /// How Fajr and Isha are bounded when the sun never reaches their angle.
    ///
    /// Defaults to `.middleOfNight`. `.none` disables the bound entirely, so
    /// an unreachable angle yields an invalid time instead.
    public var highLatitudeRule: HighLatitudeRule

    /// UTC offset for the target date (caller-provided; include DST if relevant).
    public var utcOffset: UTCOffset

    /// Observer elevation in metres (affects sunrise/sunset).
    public var elevation: Double

    /// Shafaq used by the Moonsighting method for Isha.
    public var shafaq: Shafaq

    /// Per-prayer tuning offsets in minutes (aladhan `tune`).
    public var tune: Tune

    /// Minutes before Fajr for Imsak.
    public var imsakMinutes: Int

    /// Minutes added to Dhuhr.
    public var dhuhrMinutes: Int

    /// Hijri calendar method for the date block.
    public var calendarMethod: CalendarMethod

    /// Optional timezone label echoed in `meta.timezone` (informational only).
    public var timezoneName: String?

    public init(
        method: CalculationMethod = .mwl,
        customMethod: MethodParams? = nil,
        school: AsrSchool = .standard,
        asrShadowFactor: Double? = nil,
        midnightMode: MidnightMode? = nil,
        highLatitudeRule: HighLatitudeRule = .middleOfNight,
        utcOffset: UTCOffset = .zero,
        elevation: Double = 0,
        shafaq: Shafaq = .general,
        tune: Tune = .none,
        imsakMinutes: Int = 10,
        dhuhrMinutes: Int = 0,
        calendarMethod: CalendarMethod = .hjcosa,
        timezoneName: String? = nil
    ) {
        self.method = method
        self.customMethod = customMethod
        self.school = school
        self.asrShadowFactor = asrShadowFactor
        self.midnightMode = midnightMode
        self.highLatitudeRule = highLatitudeRule
        self.utcOffset = utcOffset
        self.elevation = elevation
        self.shafaq = shafaq
        self.tune = tune
        self.imsakMinutes = imsakMinutes
        self.dhuhrMinutes = dhuhrMinutes
        self.calendarMethod = calendarMethod
        self.timezoneName = timezoneName
    }

    /// The params in effect (custom-aware).
    public var effectiveParams: MethodParams {
        method == .custom ? (customMethod ?? method.params) : method.params
    }

    /// Midnight mode after resolving overrides and the method default.
    ///
    /// Defaults to `.jafari` — the night measured from sunset to the following
    /// Fajr, which is the basis used for Midnight and the night thirds. Pass
    /// `.standard` explicitly for the sunset-to-sunrise night used by the
    /// aladhan API.
    public var resolvedMidnightMode: MidnightMode {
        midnightMode ?? effectiveParams.midnightMode ?? .jafari
    }

    /// Asr shadow factor after resolving the override / school.
    public var resolvedShadowFactor: Double {
        asrShadowFactor ?? Double(school.shadowFactor)
    }

    /// High-latitude rule in effect.
    ///
    /// Kept as a separate property for the aladhan `meta` echo; the
    /// Moonsighting method supplies its own seasonal bounds and only consults
    /// this to see whether bounding is switched off entirely.
    public var resolvedHighLatitudeRule: HighLatitudeRule { highLatitudeRule }

    /// A copy with `mutate` applied — the Swift spelling of Dart's `copyWith`.
    public func with(_ mutate: (inout CalculationParameters) -> Void) -> CalculationParameters {
        var copy = self
        mutate(&copy)
        return copy
    }
}
