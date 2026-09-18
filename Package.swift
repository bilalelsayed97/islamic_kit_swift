// swift-tools-version: 5.9
import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "IslamicKitPlus",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Core: prayer times, Hijri calendar, qibla, calendars, aladhan JSON,
        // EN/AR labels and the curated offline geocoder. Foundation only.
        .library(name: "IslamicKitPlus", targets: ["IslamicKitPlus"]),
        // Optional: the bundled 37 MB SQLite city database (geocoder +
        // directory). Link it only in targets that need city lookups.
        .library(name: "IslamicKitPlusGeocoding", targets: ["IslamicKitPlusGeocoding"]),
    ],
    targets: [
        .target(
            name: "IslamicKitPlus",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "IslamicKitPlusGeocoding",
            dependencies: ["IslamicKitPlus"],
            resources: [.copy("Resources/prayer_times.db")],
            swiftSettings: strictConcurrency,
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "IslamicKitPlusTests",
            dependencies: ["IslamicKitPlus"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "IslamicKitPlusGeocodingTests",
            dependencies: ["IslamicKitPlusGeocoding"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
