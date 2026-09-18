import Foundation

private final class BundleToken {}

extension Bundle {
    /// The bundle carrying `prayer_times.db`: SwiftPM's generated resource
    /// bundle, or the CocoaPods `IslamicKitPlusGeocoding.bundle` placed next
    /// to the framework/static library.
    static var geocodingResources: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let host = Bundle(for: BundleToken.self)
        let candidates = [host.resourceURL, Bundle.main.resourceURL]
        for base in candidates {
            if let url = base?.appendingPathComponent("IslamicKitPlusGeocoding.bundle"),
               let bundle = Bundle(url: url) {
                return bundle
            }
        }
        return host
        #endif
    }
}
