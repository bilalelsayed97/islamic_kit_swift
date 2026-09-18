import Foundation

/// Locates the bundled `prayer_times.db` and, when an app needs a copy it can
/// share (an App Group container for a widget extension, say), materializes
/// it on disk.
///
/// The database is read-only and ships with `journal_mode=delete` and no
/// sidecar files, so it can be opened directly inside the bundle — that is
/// what `SqliteCityGeocoder.bundled()` and `SqliteCityDirectory.bundled()`
/// do. `materialize(into:)` exists for the sharing case and mirrors the Dart
/// package's `openBytes`: the copy is reused when it exists and is non-empty.
public enum BundledCityDatabase {
    /// Schema version of the bundled database (`PRAGMA user_version`).
    public static let version = "2"

    /// The resource's file name inside the bundle.
    public static let resourceName = "prayer_times.db"

    /// The file name `materialize(into:)` writes. It carries the schema
    /// version so a future database update lands under a new name instead of
    /// colliding with a stale copy.
    public static let materializedFileName = "islamic_kit_plus_prayer_times_v\(version).db"

    /// Errors specific to locating or copying the bundled database.
    public enum Error: Swift.Error, Equatable, LocalizedError {
        /// `prayer_times.db` is not in the resource bundle (the product was
        /// linked without its resources).
        case resourceNotFound

        public var errorDescription: String? {
            "IslamicKitPlusGeocoding resource \(BundledCityDatabase.resourceName) not found in its bundle."
        }
    }

    /// The bundled database's location on disk.
    public static func url() throws -> URL {
        guard let url = Bundle.geocodingResources.url(forResource: "prayer_times", withExtension: "db") else {
            throw Error.resourceNotFound
        }
        return url
    }

    /// Copies the bundled database into `directory` as `materializedFileName`
    /// and returns the file's URL.
    ///
    /// The copy is reused when it already exists with a non-zero size, so
    /// calling this on every launch is cheap. `directory` is created when
    /// missing. Copying 37 MB takes a moment — call it off the main thread.
    @discardableResult
    public static func materialize(
        into directory: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let target = directory.appendingPathComponent(materializedFileName)
        if isNonEmptyFile(target, fileManager) { return target }
        let source = try url()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        // Write to a temporary sibling first so an interrupted copy never
        // leaves a truncated file that would pass the size check.
        let temporary = directory.appendingPathComponent("\(materializedFileName).tmp")
        if fileManager.fileExists(atPath: temporary.path) {
            try fileManager.removeItem(at: temporary)
        }
        try fileManager.copyItem(at: source, to: temporary)
        if fileManager.fileExists(atPath: target.path) {
            try fileManager.removeItem(at: target)
        }
        try fileManager.moveItem(at: temporary, to: target)
        return target
    }

    private static func isNonEmptyFile(_ file: URL, _ fileManager: FileManager) -> Bool {
        let size = (try? fileManager.attributesOfItem(atPath: file.path))?[.size] as? NSNumber
        return (size?.intValue ?? 0) > 0
    }
}
