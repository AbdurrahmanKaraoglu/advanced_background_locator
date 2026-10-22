# advanced_background_locator

A Flutter plugin that keeps receiving location updates while the app is in the background.

[Türkçe açıklama aşağıda.](#türkçe)

<p>
  <img src="https://raw.githubusercontent.com/AbdurrahmanKaraoglu/advanced_background_locator/main/doc/screenshots/idle.png" width="230" alt="Example app before tracking starts">
  <img src="https://raw.githubusercontent.com/AbdurrahmanKaraoglu/advanced_background_locator/main/doc/screenshots/tracking.png" width="230" alt="Example app receiving background locations">
  <img src="https://raw.githubusercontent.com/AbdurrahmanKaraoglu/advanced_background_locator/main/doc/screenshots/notification.png" width="230" alt="Android foreground service notification">
</p>

- **Android:** a foreground service (`foregroundServiceType="location"`) with a persistent notification runs a background Flutter isolate. Locations come from the Fused Location Provider (Google Play services) or the platform `LocationManager`.
- **iOS:** `CLLocationManager` with `allowsBackgroundLocationUpdates`, plus significant location changes and region monitoring to relaunch the app.

Your callbacks run in a **separate background isolate**, not in your UI isolate. Use `IsolateNameServer`/`SendPort` (see the example) to send data back to the UI.

## Requirements

| | Minimum |
|---|---|
| Flutter / Dart | 3.32 / 3.8 |
| Android | API 24, built with compileSdk 36 |
| iOS | 13.0 |

## Installation

```yaml
dependencies:
  advanced_background_locator: ^0.1.4
```

## Android setup

The plugin manifest already declares the foreground service, the boot receiver and these permissions:
`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`.

If you upgraded from 0.0.x, **remove** the `IsolateHolderService` `<service>` and `BootBroadcastReceiver` `<receiver>` entries from your app manifest.

1. If you need location while the app is not visible and want tracking to resume after a reboot, declare background location in `android/app/src/main/AndroidManifest.xml`. Google Play reviews apps that use it, so only add it if your feature needs it:

   ```xml
   <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
   ```

2. Make the main activity `singleTop` so notification taps reach the running app:

   ```xml
   <activity android:name=".MainActivity" android:launchMode="singleTop" ...>
   ```

3. Request permissions at runtime (for example with [`permission_handler`](https://pub.dev/packages/permission_handler)) **before** calling `registerLocationUpdate`:
   - `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` (required, otherwise a `PERMISSION_DENIED` `PlatformException` is thrown),
   - `POST_NOTIFICATIONS` on Android 13+ (otherwise the service runs but its notification is hidden),
   - optionally `ACCESS_BACKGROUND_LOCATION` ("Allow all the time"), which Android 11+ only grants in a separate request after foreground location.

Platform rules to keep in mind:

- **Android 12+:** a foreground service cannot be started while the app is in the background. Call `registerLocationUpdate` while your UI is visible; otherwise a `SERVICE_START_FAILED` `PlatformException` is thrown.
- **Android 14+:** the service is started with the `location` type, which requires a granted location permission at that moment.
- **Reboot:** tracking is resumed after `BOOT_COMPLETED` only if it was running before the reboot (it was not stopped with `unRegisterLocationUpdate`) and background location is granted.
- `wakeLockTime` (minutes) limits how long the partial wake lock is held.
- **Stopped in the background?** Some manufacturers (Xiaomi, Huawei, Samsung, …) stop background work aggressively. [`background_doctor`](https://pub.dev/packages/background_doctor) diagnoses why background work stopped and why the app was killed.

## iOS setup

> The iOS implementation could not be compiled on the maintainer's current (Windows) machine since 0.1.0, including the Swift Package Manager support added in 0.1.3. Please report any build problems.

The plugin supports both CocoaPods and Swift Package Manager.

1. Add usage descriptions and the location background mode to `ios/Runner/Info.plist`:

   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Why your app needs location while in use.</string>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>Why your app needs location in the background.</string>
   <key>UIBackgroundModes</key>
   <array>
       <string>location</string>
   </array>
   ```

2. Register plugins for the background isolate in `AppDelegate.swift`, so plugins such as `path_provider` work in your callbacks:

   ```swift
   import Flutter
   import UIKit
   import advanced_background_locator

   func registerPlugins(registry: FlutterPluginRegistry) {
     if !registry.hasPlugin("BackgroundLocatorPlugin") {
       GeneratedPluginRegistrant.register(with: registry)
     }
   }

   @main
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       GeneratedPluginRegistrant.register(with: self)
       BackgroundLocatorPlugin.setPluginRegistrantCallback(registerPlugins)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

3. `registerLocationUpdate` calls `requestAlwaysAuthorization`. iOS first grants "While Using" and may later ask the user to upgrade to "Always".

## Usage

All callbacks must be **top-level or static** functions annotated with `@pragma('vm:entry-point')`, so they can be looked up from the background isolate (and are not removed by tree shaking in release builds). Passing a closure throws an `ArgumentError`.

```dart
import 'package:advanced_background_locator/advanced_background_locator.dart';

@pragma('vm:entry-point')
void onLocation(LocationDto location) {
  // Runs in the background isolate.
  print('${location.latitude}, ${location.longitude}');
}

@pragma('vm:entry-point')
void onInit(Map<String, dynamic> data) {}

@pragma('vm:entry-point')
void onDispose() {}

@pragma('vm:entry-point')
void onNotificationTap() {}

Future<void> start() async {
  await AdvancedBackgroundLocator.initialize();

  await AdvancedBackgroundLocator.registerLocationUpdate(
    onLocation,
    initCallback: onInit,
    initDataCallback: {'startedAt': DateTime.now().toIso8601String()},
    disposeCallback: onDispose,
    autoStop: false, // true: stop when the app goes to the background
    iosSettings: const IOSSettings(
      accuracy: LocationAccuracy.NAVIGATION,
      distanceFilter: 0,
      showsBackgroundLocationIndicator: true,
      stopWithTerminate: false,
    ),
    androidSettings: const AndroidSettings(
      accuracy: LocationAccuracy.NAVIGATION,
      interval: 5, // seconds
      distanceFilter: 0, // meters
      wakeLockTime: 60, // minutes
      client: LocationClient.google, // or LocationClient.android
      androidNotificationSettings: AndroidNotificationSettings(
        notificationChannelName: 'Location tracking',
        notificationTitle: 'Tracking location',
        notificationMsg: 'Your location is being recorded',
        notificationIcon: '', // mipmap/drawable name, defaults to the app icon
        notificationTapCallback: onNotificationTap,
      ),
    ),
  );
}

Future<void> stop() => AdvancedBackgroundLocator.unRegisterLocationUpdate();
```

Call `initialize()` before `registerLocationUpdate()`, otherwise a `NOT_INITIALIZED` `PlatformException` is thrown.
Calling `registerLocationUpdate()` again while tracking is running restarts tracking with the new settings and callbacks
(on Android the previous `disposeCallback` and the new `initCallback` are called).

The plugin itself shows no text except the Android foreground service notification. Its default texts are English; pass
`AndroidNotificationSettings` (and `updateNotificationText`) strings in your app's language. The example app does this with
`gen-l10n` (English and Turkish).

On Android, `LocationClient.google` falls back to the platform `LocationManager` on devices without Google Play services.

Other APIs:

- `AdvancedBackgroundLocator.isServiceRunning()` / `isRegisterLocationUpdate()`
- `AdvancedBackgroundLocator.updateNotificationText(title:, msg:, bigMsg:)` (Android only)

### LocationDto

`latitude`, `longitude`, `accuracy`, `altitude`, `speed`, `speedAccuracy`, `heading`, `time` (milliseconds since epoch), `isMocked` (Android, iOS 15+), `provider` (Android only, empty on iOS).

### Accuracy mapping

| `LocationAccuracy` | Android (`Priority`) | iOS |
|---|---|---|
| `POWERSAVE` | `PRIORITY_PASSIVE` | `kCLLocationAccuracyKilometer` |
| `LOW` | `PRIORITY_LOW_POWER` | `kCLLocationAccuracyHundredMeters` |
| `BALANCED` | `PRIORITY_BALANCED_POWER_ACCURACY` | `kCLLocationAccuracyNearestTenMeters` |
| `HIGH` | `PRIORITY_HIGH_ACCURACY` | `kCLLocationAccuracyBest` |
| `NAVIGATION` | `PRIORITY_HIGH_ACCURACY` | `kCLLocationAccuracyBestForNavigation` |

## Use with other packages

These pure Dart packages work with the `LocationDto` stream of this plugin and do not depend on it:

- [`advanced_geofence`](https://pub.dev/packages/advanced_geofence): turns locations into `enter`, `exit` and `dwell` events for circle and polygon geofences. Run it inside the background callback:

  ```dart
  @pragma('vm:entry-point')
  void onLocation(LocationDto dto) {
    final result = engine.process(GeoPoint(
      dto.latitude,
      dto.longitude,
      accuracy: dto.accuracy,
      time: DateTime.fromMillisecondsSinceEpoch(dto.time.toInt()),
    ));
    // handle result.events, save engine.state
  }
  ```

- [`route_simulator`](https://pub.dev/packages/route_simulator): plays realistic fake routes for tests, demos and the Android emulator. `SimulatedLocation.toMap()` uses the same keys, so `LocationDto.fromJson(location.toMap())` works.

## Other packages

More packages by the same publisher:

- [`google_maps_polyline`](https://pub.dev/packages/google_maps_polyline): Google Directions routes and polyline encode/decode (pure Dart)
- [`marker_crafter`](https://pub.dev/packages/marker_crafter): Custom Google Maps markers drawn with Canvas
- [`animated_route_marker`](https://pub.dev/packages/animated_route_marker): Smoothly animated map marker along a route or live GPS
- [`advanced_geofence`](https://pub.dev/packages/advanced_geofence): Pure Dart geofencing engine: enter, exit and dwell events
- [`route_simulator`](https://pub.dev/packages/route_simulator): Realistic fake GPS streams for testing and demos
- [`background_doctor`](https://pub.dev/packages/background_doctor): Diagnoses why background work stops on Android and why the app was killed
- [`scan_tally`](https://pub.dev/packages/scan_tally): Continuous barcode scanning for stock counts: dedupe, tally, feedback, GS1
- [`scan_tally_mobile_scanner`](https://pub.dev/packages/scan_tally_mobile_scanner): mobile_scanner camera adapter for scan_tally
- [`turkish_kit`](https://pub.dev/packages/turkish_kit): Turkish validators, money in words, casing, provinces, holidays (pure Dart)
- [`turkish_kit_flutter`](https://pub.dev/packages/turkish_kit_flutter): Flutter widgets for turkish_kit: Turkish money field and input formatters
- [`flutter_toastify`](https://pub.dev/packages/flutter_toastify): Animated toast notifications

## Example

See the [`example`](example) directory for a complete app (English and Turkish) that logs locations to a file and shows them in the UI.

## License

MIT, see [LICENSE](LICENSE).

## Türkçe

Uygulama arka plandayken de konum güncellemesi almaya devam eden bir Flutter eklentisi. Android'de kalıcı bildirimli bir ön plan servisi
(`foregroundServiceType="location"`), iOS'ta `CLLocationManager` arka plan konum güncellemeleri kullanılır. Callback'ler ayrı bir arka plan
isolate'inde çalışır; bu yüzden üst düzey ya da statik ve `@pragma('vm:entry-point')` ile işaretlenmiş fonksiyonlar olmalıdır.

Kurulum, izinler ve kullanım için yukarıdaki İngilizce bölümlere bakın. Örnek uygulama İngilizce ve Türkçe arayüzlüdür.

Arka planda servis durduruluyorsa (Xiaomi, Huawei, Samsung gibi üreticilerde sık görülür)
[`background_doctor`](https://pub.dev/packages/background_doctor) arka plan işinin neden durduğunu teşhis eder.

### Diğer paketler

Aynı yayıncının diğer paketleri:

- [`google_maps_polyline`](https://pub.dev/packages/google_maps_polyline): Google Directions rotası ve polyline kodlama/çözme (saf Dart)
- [`marker_crafter`](https://pub.dev/packages/marker_crafter): Canvas ile çizilen özel Google Maps işaretçileri
- [`animated_route_marker`](https://pub.dev/packages/animated_route_marker): Rota ya da canlı GPS üzerinde akıcı hareket eden harita işaretçisi
- [`advanced_geofence`](https://pub.dev/packages/advanced_geofence): Saf Dart geofence motoru: giriş, çıkış ve bekleme olayları
- [`route_simulator`](https://pub.dev/packages/route_simulator): Test ve demo için gerçekçi sahte GPS akışı
- [`background_doctor`](https://pub.dev/packages/background_doctor): Android'de arka plan işinin neden durduğunu ve uygulamanın neden kapandığını teşhis eder
- [`scan_tally`](https://pub.dev/packages/scan_tally): Stok sayımı için sürekli barkod okutma: tekrar ayıklama, sayım, geri bildirim, GS1
- [`scan_tally_mobile_scanner`](https://pub.dev/packages/scan_tally_mobile_scanner): scan_tally için mobile_scanner kamera adaptörü
- [`turkish_kit`](https://pub.dev/packages/turkish_kit): Türkçe doğrulayıcılar, tutarı yazıyla yazma, harf dönüşümü, il/ilçe, tatiller (saf Dart)
- [`turkish_kit_flutter`](https://pub.dev/packages/turkish_kit_flutter): turkish_kit için Flutter bileşenleri: Türk biçimli para alanı ve girdi biçimleyicileri
- [`flutter_toastify`](https://pub.dev/packages/flutter_toastify): Animasyonlu toast bildirimleri
