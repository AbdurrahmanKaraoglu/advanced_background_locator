// ignore_for_file: constant_identifier_names

/// Desired location accuracy. See the README for the platform mapping.
class LocationAccuracy {
  const LocationAccuracy._internal(this.value);

  /// Value sent to the native side.
  final int value;

  /// Lowest power use; Android passive provider, iOS ~1 km.
  static const LocationAccuracy POWERSAVE = LocationAccuracy._internal(0);

  /// Low power; city-block level (Android low power, iOS ~100 m).
  static const LocationAccuracy LOW = LocationAccuracy._internal(1);

  /// Balanced power and accuracy (Android balanced, iOS ~10 m).
  static const LocationAccuracy BALANCED = LocationAccuracy._internal(2);

  /// High accuracy (Android high accuracy, iOS best).
  static const LocationAccuracy HIGH = LocationAccuracy._internal(3);

  /// Highest accuracy (Android high accuracy, iOS best for navigation).
  static const LocationAccuracy NAVIGATION = LocationAccuracy._internal(4);
}

/// Settings shared by `AndroidSettings` and `IOSSettings`.
class LocatorSettings {
  /// Desired accuracy of the locations.
  final LocationAccuracy accuracy;

  /// Minimum distance in meters between two location updates; 0 disables
  /// the filter.
  final double distanceFilter;

  /// Creates settings with the given [accuracy] and [distanceFilter].
  const LocatorSettings({required this.accuracy, required this.distanceFilter});
}
