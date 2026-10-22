## 0.1.4

- DOCS: README lists the other 11 packages by the same publisher and links `background_doctor` for apps stopped in the background; added a short Turkish section. / README'ye aynı yayıncının diğer 11 paketi, arka planda durdurulma için `background_doctor` bağlantısı ve kısa bir Türkçe bölüm eklendi.

## 0.1.3

### Added
- iOS: Swift Package Manager support (`ios/advanced_background_locator/Package.swift`). CocoaPods keeps working; the sources moved to `ios/advanced_background_locator/Sources/`. Not build-verified on iOS yet.
- API documentation (dartdoc) for the public API.
- Screenshots and a "Use with other packages" section (advanced_geofence, route_simulator) in the README.

### Changed
- Android: `play-services-location` 21.4.0, `core-ktx` 1.18.0, `gson` 2.14.0.
- Example: modern Material 3 UI with English and Turkish localization.

## 0.1.2

### Fixed
- Android: the first location (e.g. the last known location reported right away) could reach the callback before `initCallback` ran. Location updates are now requested after the init callback is queued.
- Dart: background callbacks now run one at a time in arrival order, so an async `initCallback` completes before the first location callback starts (previously they could interleave, e.g. corrupting concurrent file writes).

## 0.1.1

### Fixed
- iOS: tracking stopped with `unRegisterLocationUpdate` could resume after the app was terminated, because a region was still monitored on termination.
- iOS: when several locations were delivered at once the oldest one was reported instead of the most recent one.
- Android: calling `registerLocationUpdate` while tracking was running silently ignored the new settings and callbacks; it now restarts tracking with them.
- Android/iOS: `registerLocationUpdate` without a prior `initialize()` now throws a `NOT_INITIALIZED` `PlatformException` instead of never delivering locations.
- Android: `LocationClient.google` falls back to `LocationManager` when Google Play services are unavailable.

## 0.1.0

### Breaking
- Requires Dart 3.8 / Flutter 3.32 or newer. Android `minSdk` is now 24, iOS deployment target 13.0.
- The plugin manifest now declares the `IsolateHolderService` foreground service (`foregroundServiceType="location"`, not exported) and the boot receiver. Remove the `<service>` and `<receiver>` entries you copied into your app manifest.
- `AutoStopHandler` no longer stops tracking on `AppLifecycleState.inactive` (reported for calls, Control Center, etc.); it stops on `hidden`, `paused` and `detached`.
- `LocationAccuracy.HIGH` now maps to `PRIORITY_HIGH_ACCURACY` on Android (was balanced power).

### Fixed
- Android: location maps used `isMocked`/`speedAccuracy` keys while Dart expected `is_mocked`/`speed_accuracy`, so every location update failed to parse.
- Android: notification icon color, callback handles, interval and distance filter were cast to fixed number types and could crash or be dropped depending on their value.
- Android: the wake lock was never released, background Flutter engines were leaked, pluggable callbacks were registered again on every start and the init/dispose callbacks of an earlier registration were reused.
- Android: tracking restarted after every reboot even after `unRegisterLocationUpdate`; it now only resumes when tracking was active and background location is granted.
- Android: `updateNotificationText` never completed when the service was not running.
- Android: a missing notification icon crashed the service; it falls back to the app icon. Notification taps now also work when the activity was recreated.
- Dart: `LocationDto.fromJson` accepts ints and missing optional fields (iOS sends no `provider`); the init callback receives a `Map<String, dynamic>`; missing callback handles no longer throw in the background isolate.
- Dart: passing a closure instead of a top-level/static function now throws a clear `ArgumentError`.
- iOS: the headless engine is no longer started twice when `initialize()` is called again; missing init data and missing plugin registrant callback no longer crash; `is_mocked` (iOS 15+) and `provider` are reported.

### Changed
- Android: AGP 9 / Kotlin 2.4 / compileSdk 36, `LocationRequest.Builder`, `Priority` constants, `Location.isMock`, `ServiceCompat.startForeground` with the location service type, `FOREGROUND_SERVICE_LOCATION` and `POST_NOTIFICATIONS` permissions.
- Android: starting the service while the app is in the background (Android 12+) or without location permission returns a `PlatformException` instead of crashing.
- iOS: added a privacy manifest (`NSUserDefaults`, reason `CA92.1`).
- `package:advanced_background_locator/advanced_background_locator.dart` now also exports `LocationDto` and the settings classes.
- Updated `flutter_lints` to 6.0, rewrote the README and the example app, added unit tests.

## 0.0.3 - 2024-09-05
- Readme updated.

## 0.0.2 - 2024-09-05
- Fixed a bug in location service.
- Improved performance for network requests.

## 0.0.1
- Initial release.
