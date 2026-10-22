# advanced_background_locator example

A Material 3 app (English and Turkish) that starts and stops background location tracking,
shows the last location and an activity log written by the background isolate.

- `lib/main.dart`: UI, permission requests and `registerLocationUpdate` settings.
- `lib/location_callback_handler.dart`: background callbacks (`@pragma('vm:entry-point')`).
- `lib/location_service_repository.dart`: writes locations to a log file and forwards them to the UI through a `SendPort`.

```bash
flutter run
```

On an emulator, send locations from *Extended controls → Location*, or play a route with
[`route_simulator`](https://pub.dev/packages/route_simulator).
