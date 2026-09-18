/// Supplies seasonal Fajr/Isha twilight for methods that do not use a fixed
/// angle — today only the Moonsighting Committee Worldwide method.
///
/// Implementations return whole seconds relative to sunrise/sunset. The engine
/// owns how those values are combined with the angle-based candidates (the
/// seasonal values act as *bounds*, not replacements), so a strategy only has
/// to answer the seasonal question.
public protocol TwilightStrategy: Sendable {
    /// Seconds **before** sunrise at which Fajr begins on `date` at `latitude`.
    func fajrSecondsBeforeSunrise(_ date: CivilDate, latitude: Double) -> Int

    /// Seconds **after** sunset at which Isha begins on `date` at `latitude`,
    /// for the requested `shafaq` (twilight colour).
    func ishaSecondsAfterSunset(_ date: CivilDate, latitude: Double, shafaq: Shafaq) -> Int
}
