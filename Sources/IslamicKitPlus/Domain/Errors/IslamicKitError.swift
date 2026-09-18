import Foundation

/// Errors thrown by the package. `ArgumentError`s in the Dart package map to
/// the first three cases, `StateError`s to the last three.
public enum IslamicKitError: Error, Equatable, Sendable {
    /// A Gregorian date outside the calendar table's range. The payload is the
    /// Dart message, e.g. `"Gregorian date out of range for UAQ ((1937, 3, 14) .. (2077, 11, 16))."`.
    case gregorianDateOutOfRange(String)

    /// A Hijri date outside the calendar table's range (payload as above).
    case hijriDateOutOfRange(String)

    /// An invalid calendar range (`end` before `start`, or more than 11 months).
    case invalidDateRange(String)

    /// The geocoder returned no match for `query`.
    case locationNotFound(query: String)

    /// The operation needs a `CityDirectory` and the service has none.
    case directoryRequired

    /// The method needs a `TwilightStrategy` and none was supplied.
    case twilightStrategyRequired(method: String)

    /// The message the Dart package would have raised.
    public var message: String {
        switch self {
        case .gregorianDateOutOfRange(let m), .hijriDateOutOfRange(let m), .invalidDateRange(let m):
            return m
        case .locationNotFound(let query):
            return "Location not found: \"\(query)\"."
        case .directoryRequired:
            return "This operation needs the bundled city database. Construct "
                + "PrayerTimesService with `directory:` (see SqliteCityDirectory "
                + "in IslamicKitPlusGeocoding)."
        case .twilightStrategyRequired(let method):
            return "The \(method) method needs a TwilightStrategy. "
                + "Pass one to AstronomicalCalculator.compute()."
        }
    }
}

extension IslamicKitError: LocalizedError {
    public var errorDescription: String? { message }
}
