#
# Run `pod lib lint IslamicKitPlus.podspec --allow-warnings --skip-tests` to
# validate this spec before tagging a release.
#
# The Swift Package (Package.swift) is the primary distribution; this spec
# mirrors its two products as subspecs so CocoaPods projects can use the
# same sources. `Core` is the default; add `Geocoding` for the bundled
# 37 MB SQLite city database. With CocoaPods both subspecs compile into the
# single `IslamicKitPlus` module (there is no `IslamicKitPlusGeocoding`
# module to import).
#

Pod::Spec.new do |s|
  s.name             = 'IslamicKitPlus'
  s.version          = '0.3.1'
  s.summary          = 'Offline prayer times, Hijri calendar, qibla and city geocoding for Swift.'

  s.description      = <<-DESC
Native Swift port of the Dart package islamic_kit_plus. Computes prayer
times from Jean Meeus' solar position (34 calculation methods, Asr schools,
high-latitude rules, per-prayer tuning), a four-method Hijri calendar,
qibla, monthly/annual/range calendars, aladhan.com-shaped JSON and
English/Arabic labels - all offline, Foundation only. The optional
Geocoding subspec adds an offline city geocoder and city directory over a
bundled SQLite database of 265,849 places.
                       DESC

  s.homepage         = 'https://github.com/bilalelsayed97/islamic_kit_swift'
  s.license          = { :type => 'GPL-3.0', :file => 'LICENSE' }
  s.author           = { 'Bilal Elsayed' => 'bilalelsayed97@gmail.com' }
  s.source           = { :git => 'https://github.com/bilalelsayed97/islamic_kit_swift.git', :tag => s.version.to_s }

  s.swift_versions   = ['5.9']
  s.ios.deployment_target     = '13.0'
  s.osx.deployment_target     = '10.15'
  s.tvos.deployment_target    = '13.0'
  s.watchos.deployment_target = '6.0'

  s.static_framework = true

  # Safe to link from widget / app extensions: the library never touches
  # UIApplication or other extension-unsafe API.
  s.pod_target_xcconfig = {
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    # Core and Geocoding share `package`-level declarations. SwiftPM sets the
    # package name automatically; CocoaPods needs it spelled out so those
    # declarations compile when both subspecs are built as one module.
    'SWIFT_PACKAGE_NAME' => 'islamic_kit_swift',
  }

  s.default_subspecs = 'Core'

  # Prayer times, Hijri calendar, qibla, calendars, aladhan JSON, EN/AR
  # labels and the curated offline geocoder. Foundation only, no database.
  s.subspec 'Core' do |core|
    core.source_files = 'Sources/IslamicKitPlus/**/*.swift'
  end

  # The bundled SQLite city database: `SqliteCityGeocoder` and
  # `SqliteCityDirectory` over 265,849 places (131k populated settlements)
  # with English + Arabic names, coordinates and standard-time offsets.
  s.subspec 'Geocoding' do |geo|
    geo.dependency 'IslamicKitPlus/Core'
    geo.source_files = 'Sources/IslamicKitPlusGeocoding/**/*.swift'
    geo.resource_bundles = {
      'IslamicKitPlusGeocoding' => ['Sources/IslamicKitPlusGeocoding/Resources/prayer_times.db']
    }
    geo.libraries = 'sqlite3'
  end
end
