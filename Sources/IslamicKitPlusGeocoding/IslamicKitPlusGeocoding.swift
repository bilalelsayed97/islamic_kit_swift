// IslamicKitPlusGeocoding — the optional bundled SQLite city database.
//
// Adds `SqliteCityGeocoder` (a `Geocoder` over ≈131k populated places with
// English + Arabic names) and `SqliteCityDirectory` (the `CityDirectory`
// port: countries, city pages, reverse geocoding, per-country timezones),
// both reading the 37 MB `prayer_times.db` shipped as a resource of this
// target. `BundledCityDatabase` locates the file and can copy it into an
// App Group container for sharing with extensions.
//
// Importing this module re-exports `IslamicKitPlus`. (Under CocoaPods both
// products compile into the single `IslamicKitPlus` module, so there is
// nothing separate to re-export.)

#if SWIFT_PACKAGE
@_exported import IslamicKitPlus
#endif
