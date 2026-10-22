import 'package:advanced_background_locator/keys.dart';
import 'package:advanced_background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';

/// Location provider used on Android.
enum LocationClient {
  /// Fused Location Provider from Google Play services. Falls back to
  /// [android] on devices without Google Play services.
  google,

  /// The platform `LocationManager` (GPS and network providers).
  android,
}

/// Texts and appearance of the Android foreground service notification.
///
/// Android requires this notification while tracking runs. Pass texts in
/// your app's language; the defaults are English.
class AndroidNotificationSettings {
  /// Name of the notification channel shown in the system settings.
  final String notificationChannelName;

  /// Title of the notification.
  final String notificationTitle;

  /// Text of the collapsed notification.
  final String notificationMsg;

  /// Text of the expanded notification.
  final String notificationBigMsg;

  /// Name of a `mipmap` or `drawable` resource used as the small icon; empty
  /// uses the app icon. Android shows only the alpha channel, so use a
  /// transparent, single-color icon.
  final String notificationIcon;

  /// Accent color of the notification icon.
  final Color notificationIconColor;

  /// Called in the background isolate when the user taps the notification.
  /// Must be a top-level or static function.
  final VoidCallback? notificationTapCallback;

  /// Creates notification settings with English default texts.
  const AndroidNotificationSettings({
    this.notificationChannelName = 'Location tracking',
    this.notificationTitle = 'Start Location Tracking',
    this.notificationMsg = 'Track location in background',
    this.notificationBigMsg =
        'Background location is on to keep the app up-to-date with your location. This is required for main features to work properly when the app is not running.',
    this.notificationIcon = '',
    this.notificationIconColor = Colors.grey,
    this.notificationTapCallback,
  });
}

/// Android specific tracking settings.
class AndroidSettings extends LocatorSettings {
  /// Foreground service notification shown while tracking runs.
  final AndroidNotificationSettings androidNotificationSettings;

  /// Maximum time in minutes the partial wake lock is held. Defaults to 60.
  final int wakeLockTime;

  /// Interval between location updates in seconds. Defaults to 5.
  final int interval;

  /// Location provider to use. Defaults to [LocationClient.google].
  final LocationClient client;

  /// Creates Android settings. Defaults to [LocationAccuracy.NAVIGATION],
  /// a 5 second interval and no distance filter.
  const AndroidSettings({
    super.accuracy = LocationAccuracy.NAVIGATION,
    this.interval = 5,
    super.distanceFilter = 0,
    this.androidNotificationSettings = const AndroidNotificationSettings(),
    this.wakeLockTime = 60,
    this.client = LocationClient.google,
  });

  /// Serializes the settings for the platform channel.
  Map<String, dynamic> toMap() {
    return {
      Keys.SETTINGS_ACCURACY: accuracy.value,
      Keys.SETTINGS_INTERVAL: interval,
      Keys.SETTINGS_DISTANCE_FILTER: distanceFilter,
      Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME: wakeLockTime,
      Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME:
          androidNotificationSettings.notificationChannelName,
      Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE:
          androidNotificationSettings.notificationTitle,
      Keys.SETTINGS_ANDROID_NOTIFICATION_MSG:
          androidNotificationSettings.notificationMsg,
      Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG:
          androidNotificationSettings.notificationBigMsg,
      Keys.SETTINGS_ANDROID_NOTIFICATION_ICON:
          androidNotificationSettings.notificationIcon,
      Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR: androidNotificationSettings
          .notificationIconColor
          .toARGB32(),
      Keys.SETTINGS_ANDROID_LOCATION_CLIENT: client.index,
    };
  }
}
