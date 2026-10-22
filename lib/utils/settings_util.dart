import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:advanced_background_locator/keys.dart';
import 'package:advanced_background_locator/location_dto.dart';
import 'package:advanced_background_locator/settings/android_settings.dart';
import 'package:advanced_background_locator/settings/ios_settings.dart';

class SettingsUtil {
  static Map<String, dynamic> getArgumentsMap({
    required void Function(LocationDto) callback,
    void Function(Map<String, dynamic>)? initCallback,
    Map<String, dynamic>? initDataCallback,
    void Function()? disposeCallback,
    AndroidSettings androidSettings = const AndroidSettings(),
    IOSSettings iosSettings = const IOSSettings(),
  }) {
    final args = _getCommonArgumentsMap(
      callback: callback,
      initCallback: initCallback,
      initDataCallback: initDataCallback,
      disposeCallback: disposeCallback,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      args.addAll(_getAndroidArgumentsMap(androidSettings));
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      args.addAll(_getIOSArgumentsMap(iosSettings));
    }

    return args;
  }

  static Map<String, dynamic> _getCommonArgumentsMap({
    required void Function(LocationDto) callback,
    void Function(Map<String, dynamic>)? initCallback,
    Map<String, dynamic>? initDataCallback,
    void Function()? disposeCallback,
  }) {
    final Map<String, dynamic> args = {
      Keys.ARG_CALLBACK: _rawHandle(callback, 'callback'),
    };

    if (initCallback != null) {
      args[Keys.ARG_INIT_CALLBACK] = _rawHandle(initCallback, 'initCallback');
    }
    if (disposeCallback != null) {
      args[Keys.ARG_DISPOSE_CALLBACK] = _rawHandle(
        disposeCallback,
        'disposeCallback',
      );
    }
    if (initDataCallback != null) {
      args[Keys.ARG_INIT_DATA_CALLBACK] = initDataCallback;
    }

    return args;
  }

  static Map<String, dynamic> _getAndroidArgumentsMap(
    AndroidSettings androidSettings,
  ) {
    final Map<String, dynamic> args = {
      Keys.ARG_SETTINGS: androidSettings.toMap(),
    };

    if (androidSettings.androidNotificationSettings.notificationTapCallback !=
        null) {
      args[Keys.ARG_NOTIFICATION_CALLBACK] = _rawHandle(
        androidSettings.androidNotificationSettings.notificationTapCallback!,
        'notificationTapCallback',
      );
    }

    return args;
  }

  /// Background callbacks are looked up by handle, which only exists for top-level and static functions.
  static int _rawHandle(Function callback, String name) {
    final handle = PluginUtilities.getCallbackHandle(callback);
    if (handle == null) {
      throw ArgumentError.value(
        callback,
        name,
        'Must be a top-level or static function',
      );
    }
    return handle.toRawHandle();
  }

  static Map<String, dynamic> _getIOSArgumentsMap(IOSSettings iosSettings) {
    return iosSettings.toMap();
  }
}
