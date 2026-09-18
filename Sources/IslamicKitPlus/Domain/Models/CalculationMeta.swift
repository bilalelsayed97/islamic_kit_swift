/// Echo of the settings used for a calculation (mirrors aladhan `meta`).
public struct CalculationMeta: Hashable, Sendable {
    public let coordinates: Coordinates

    /// Timezone label (an IANA name if the caller supplied one, else `UTC±HH:MM`).
    public let timezone: String

    public let method: CalculationMethod

    /// The effective params (equals `method.params` unless a custom method or
    /// an overriding shadow/interval was supplied).
    public let methodParams: MethodParams

    public let school: AsrSchool
    public let midnightMode: MidnightMode
    public let latitudeAdjustmentMethod: HighLatitudeRule
    public let shafaq: Shafaq

    /// Per-prayer tuning offsets in minutes.
    public let offsets: [Prayer: Int]

    public init(
        coordinates: Coordinates,
        timezone: String,
        method: CalculationMethod,
        methodParams: MethodParams,
        school: AsrSchool,
        midnightMode: MidnightMode,
        latitudeAdjustmentMethod: HighLatitudeRule,
        shafaq: Shafaq,
        offsets: [Prayer: Int]
    ) {
        self.coordinates = coordinates
        self.timezone = timezone
        self.method = method
        self.methodParams = methodParams
        self.school = school
        self.midnightMode = midnightMode
        self.latitudeAdjustmentMethod = latitudeAdjustmentMethod
        self.shafaq = shafaq
        self.offsets = offsets
    }
}
