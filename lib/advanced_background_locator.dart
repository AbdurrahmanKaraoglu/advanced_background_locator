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

class AdvancedBackgroundLocator {
  static const MethodChannel _channel = MethodChannel(Keys.CHANNEL_ID);
  static AutoStopHandler? _autoStopHandler;

  /// Must be called (and awaited) once before [registerLocationUpdate].
  static Future<void> initialize() async {
    final CallbackHandle callback = PluginUtilities.getCallbackHandle(callbackDispatcher)!;
    await _channel.invokeMethod(Keys.METHOD_PLUGIN_INITIALIZE_SERVICE, {Keys.ARG_CALLBACK_DISPATCHER: callback.toRawHandle()});
  }

  /// Starts location updates.
  ///
  /// All callbacks run in a background isolate, so they must be top-level or
  /// static functions annotated with `@pragma('vm:entry-point')`.
  static Future<void> registerLocationUpdate(void Function(LocationDto) callback,
      {void Function(Map<String, dynamic>)? initCallback,
      Map<String, dynamic> initDataCallback = const {},
      void Function()? disposeCallback,
      bool autoStop = false,
      AndroidSettings androidSettings = const AndroidSettings(),
      IOSSettings iosSettings = const IOSSettings()}) async {
    final args = SettingsUtil.getArgumentsMap(
        callback: callback, initCallback: initCallback, initDataCallback: initDataCallback, disposeCallback: disposeCallback, androidSettings: androidSettings, iosSettings: iosSettings);

    if (autoStop && _autoStopHandler == null) {
      _autoStopHandler = AutoStopHandler();
      WidgetsBinding.instance.addObserver(_autoStopHandler!);
    }

    await _channel.invokeMethod(Keys.METHOD_PLUGIN_REGISTER_LOCATION_UPDATE, args);
  }

  static Future<void> unRegisterLocationUpdate() async {
    final handler = _autoStopHandler;
    if (handler != null) {
      _autoStopHandler = null;
      WidgetsBinding.instance.removeObserver(handler);
    }
    await _channel.invokeMethod(Keys.METHOD_PLUGIN_UN_REGISTER_LOCATION_UPDATE);
  }

  static Future<bool> isRegisterLocationUpdate() async {
    return await _channel.invokeMethod<bool>(Keys.METHOD_PLUGIN_IS_REGISTER_LOCATION_UPDATE) ?? false;
  }

  static Future<bool> isServiceRunning() async {
    return await _channel.invokeMethod<bool>(Keys.METHOD_PLUGIN_IS_SERVICE_RUNNING) ?? false;
  }

  /// Updates the foreground service notification. Only applies to Android.
  static Future<void> updateNotificationText({String? title, String? msg, String? bigMsg}) async {
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
