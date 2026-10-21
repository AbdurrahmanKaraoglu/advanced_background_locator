import 'keys.dart';

class LocationDto {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;

  /// Milliseconds since epoch.
  final double time;
  final bool isMocked;
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

  static double _toDouble(Object? value) => value is num ? value.toDouble() : 0.0;

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
