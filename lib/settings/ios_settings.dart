import 'package:advanced_background_locator/keys.dart';

import 'locator_settings.dart';

/// iOS specific tracking settings.
class IOSSettings extends LocatorSettings {
  /// Shows the blue background location indicator in the status bar while
  /// the app uses location in the background.
  final bool showsBackgroundLocationIndicator;

  /// Stops location updates when the user terminates the app; otherwise
  /// region monitoring relaunches the app to resume tracking.
  final bool stopWithTerminate;

  /// Creates iOS settings. Defaults to [LocationAccuracy.NAVIGATION], no
  /// distance filter, no indicator and tracking that survives termination.
  const IOSSettings({
    super.accuracy = LocationAccuracy.NAVIGATION,
    super.distanceFilter = 0,
    this.showsBackgroundLocationIndicator = false,
    this.stopWithTerminate = false,
  });

  /// Serializes the settings for the platform channel.
  Map<String, dynamic> toMap() {
    return {
      Keys.SETTINGS_ACCURACY: accuracy.value,
      Keys.SETTINGS_DISTANCE_FILTER: distanceFilter,
      Keys.SETTINGS_IOS_SHOWS_BACKGROUND_LOCATION_INDICATOR:
          showsBackgroundLocationIndicator,
      Keys.SETTINGS_IOS_STOP_WITH_TERMINATE: stopWithTerminate,
    };
  }
}
