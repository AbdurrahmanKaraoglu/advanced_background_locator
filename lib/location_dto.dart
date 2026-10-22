import 'keys.dart';

/// A location delivered to the background callback.
class LocationDto {
  /// Latitude in degrees.
  final double latitude;

  /// Longitude in degrees.
  final double longitude;

  /// Estimated horizontal accuracy radius in meters.
  final double accuracy;

  /// Altitude in meters above the WGS 84 ellipsoid.
  final double altitude;

  /// Speed in meters per second.
  final double speed;

  /// Estimated speed accuracy in meters per second (0 on iOS).
  final double speedAccuracy;

  /// Direction of travel in degrees, clockwise from north.
  final double heading;

  /// Milliseconds since epoch.
  final double time;

  /// Whether the location comes from a mock provider (Android, iOS 15+).
  final bool isMocked;

  /// Name of the location provider, e.g. `gps` or `fused`; empty on iOS.
  final String provider;

  LocationDto._(
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.speedAccuracy,
    this.heading,
    this.time,
    this.isMocked,
    this.provider,
  );

  /// Parses the location map sent by the native side.
  ///
  /// Numbers may arrive as `int` or `double` and optional fields (`is_mocked`,
  /// `provider`, `speed_accuracy`) may be missing, e.g. on iOS.
  factory LocationDto.fromJson(Map<dynamic, dynamic> json) {
    return LocationDto._(
      _toDouble(json[Keys.ARG_LATITUDE]),
      _toDouble(json[Keys.ARG_LONGITUDE]),
      _toDouble(json[Keys.ARG_ACCURACY]),
      _toDouble(json[Keys.ARG_ALTITUDE]),
      _toDouble(json[Keys.ARG_SPEED]),
      _toDouble(json[Keys.ARG_SPEED_ACCURACY]),
      _toDouble(json[Keys.ARG_HEADING]),
      _toDouble(json[Keys.ARG_TIME]),
      json[Keys.ARG_IS_MOCKED] == true,
      json[Keys.ARG_PROVIDER] as String? ?? '',
    );
  }

  static double _toDouble(Object? value) =>
      value is num ? value.toDouble() : 0.0;

  /// Serializes the location with the same keys [LocationDto.fromJson] reads.
  Map<String, dynamic> toJson() {
    return {
      Keys.ARG_LATITUDE: latitude,
      Keys.ARG_LONGITUDE: longitude,
      Keys.ARG_ACCURACY: accuracy,
      Keys.ARG_ALTITUDE: altitude,
      Keys.ARG_SPEED: speed,
      Keys.ARG_SPEED_ACCURACY: speedAccuracy,
      Keys.ARG_HEADING: heading,
      Keys.ARG_TIME: time,
      Keys.ARG_IS_MOCKED: isMocked,
      Keys.ARG_PROVIDER: provider,
    };
  }

  @override
  String toString() {
    return 'LocationDto{latitude: $latitude, longitude: $longitude, accuracy: $accuracy, altitude: $altitude, speed: $speed, speedAccuracy: $speedAccuracy, heading: $heading, time: $time, isMocked: $isMocked, provider: $provider}';
  }
}
