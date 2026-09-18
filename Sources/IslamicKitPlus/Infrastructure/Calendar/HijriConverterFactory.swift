/// Creates the `HijriConverter` for a given `CalendarMethod`.
public struct HijriConverterFactory: Sendable {
    public init() {}

    public func create(_ method: CalendarMethod) -> any HijriConverter {
        switch method {
        case .uaq: return TableHijriConverter.ummAlQura
        case .diyanet: return TableHijriConverter.diyanet
        case .hjcosa: return HjcosaConverter()
        case .mathematical: return MathematicalConverter()
        }
    }
}
