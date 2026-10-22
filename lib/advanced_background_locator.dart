/// Location updates that keep running while the app is in the background.
///
/// On Android a foreground service with a persistent notification runs a
/// background Flutter isolate; on iOS `CLLocationManager` delivers background
/// location updates. Call [AdvancedBackgroundLocator.initialize] once, then
/// [AdvancedBackgroundLocator.registerLocationUpdate].
library;

import 'dart:ui';

import 'package:advanced_background_locator/settings/android_settings.dart';
import 'package:advanced_background_locator/settings/ios_settings.dart';
import 'package:advanced_background_locator/utils/settings_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'auto_stop_handler.dart';
import 'callback_dispatcher.dart';
import 'keys.dart';
import 'location_dto.dart';

export 'location_dto.dart';
export 'settings/android_settings.dart';
export 'settings/ios_settings.dart';
export 'settings/locator_settings.dart';

/// Starts, stops and inspects background location tracking.
///
/// Every callback passed to this class runs in a separate background isolate,
/// so it must be a top-level or static function annotated with
/// `@pragma('vm:entry-point')`. Use `IsolateNameServer` and a `SendPort` to
/// pass data back to the UI isolate.
class AdvancedBackgroundLocator {
  static const MethodChannel _channel = MethodChannel(Keys.CHANNEL_ID);
  static AutoStopHandler? _autoStopHandler;

  /// Registers the background isolate entry point with the native side.
  ///
  /// Must be called (and awaited) once before [registerLocationUpdate],
  /// otherwise registering throws a `NOT_INITIALIZED` [PlatformException].
  static Future<void> initialize() async {
    final CallbackHandle callback = PluginUtilities.getCallbackHandle(
      callbackDispatcher,
    )!;
    await _channel.invokeMethod(Keys.METHOD_PLUGIN_INITIALIZE_SERVICE, {
      Keys.ARG_CALLBACK_DISPATCHER: callback.toRawHandle(),
    });
  }

  /// Starts location updates and delivers each location to [callback].
  ///
  /// - [initCallback] runs once when tracking starts and receives
  ///   [initDataCallback]. It completes before the first location is
  ///   delivered.
  /// - [disposeCallback] runs when tracking stops.
  /// - [autoStop] stops tracking when the app leaves the foreground.
  /// - [androidSettings] and [iosSettings] configure each platform.
  ///
  /// Calling this again while tracking is running restarts tracking with the
  /// new settings and callbacks.
  ///
  /// Throws an [ArgumentError] if a callback is not a top-level or static
  /// function, and a [PlatformException] if the native side cannot start
  /// tracking (for example `PERMISSION_DENIED`, `NOT_INITIALIZED` or, on
  /// Android 12+, `SERVICE_START_FAILED` when the app is in the background).
  static Future<void> registerLocationUpdate(
    void Function(LocationDto) callback, {
    void Function(Map<String, dynamic>)? initCallback,
    Map<String, dynamic> initDataCallback = const {},
    void Function()? disposeCallback,
    bool autoStop = false,
    AndroidSettings androidSettings = const AndroidSettings(),
    IOSSettings iosSettings = const IOSSettings(),
  }) async {
    final args = SettingsUtil.getArgumentsMap(
      callback: callback,
      initCallback: initCallback,
      initDataCallback: initDataCallback,
      disposeCallback: disposeCallback,
      androidSettings: androidSettings,
      iosSettings: iosSettings,
    );

    if (autoStop && _autoStopHandler == null) {
      _autoStopHandler = AutoStopHandler();
      WidgetsBinding.instance.addObserver(_autoStopHandler!);
    }

    await _channel.invokeMethod(
      Keys.METHOD_PLUGIN_REGISTER_LOCATION_UPDATE,
      args,
    );
  }

  /// Stops location updates (and the Android foreground service).
  ///
  /// The `disposeCallback` given to [registerLocationUpdate] is called, and
  /// tracking is not resumed after a reboot.
  static Future<void> unRegisterLocationUpdate() async {
    final handler = _autoStopHandler;
    if (handler != null) {
      _autoStopHandler = null;
      WidgetsBinding.instance.removeObserver(handler);
    }
    await _channel.invokeMethod(Keys.METHOD_PLUGIN_UN_REGISTER_LOCATION_UPDATE);
  }

  /// Whether location updates are currently registered.
  static Future<bool> isRegisterLocationUpdate() async {
    return await _channel.invokeMethod<bool>(
          Keys.METHOD_PLUGIN_IS_REGISTER_LOCATION_UPDATE,
        ) ??
        false;
  }

  /// Whether the location service is currently running.
  static Future<bool> isServiceRunning() async {
    return await _channel.invokeMethod<bool>(
          Keys.METHOD_PLUGIN_IS_SERVICE_RUNNING,
        ) ??
        false;
  }

  /// Updates the texts of the foreground service notification.
  ///
  /// Only applies to Android; `null` values keep the current text. Does
  /// nothing when tracking is not running.
  static Future<void> updateNotificationText({
    String? title,
    String? msg,
    String? bigMsg,
  }) async {
    final Map<String, dynamic> arg = {};

    if (title != null) {
      arg[Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE] = title;
    }

    if (msg != null) {
      arg[Keys.SETTINGS_ANDROID_NOTIFICATION_MSG] = msg;
    }

    if (bigMsg != null) {
      arg[Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG] = bigMsg;
    }

    await _channel.invokeMethod(Keys.METHOD_PLUGIN_UPDATE_NOTIFICATION, arg);
  }
}
