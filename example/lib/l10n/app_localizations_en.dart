// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Location Tracking';

  @override
  String get appSubtitle => 'Background location service';

  @override
  String get clearLog => 'Clear log';

  @override
  String get statusActive => 'Tracking active';

  @override
  String get statusInactive => 'Tracking off';

  @override
  String get statusActiveDescription =>
      'Your location is recorded even when the app is in the background.';

  @override
  String get statusInactiveDescription =>
      'Start tracking to record your location.';

  @override
  String get badgeLive => 'Live';

  @override
  String get badgeIdle => 'Idle';

  @override
  String get startTracking => 'Start tracking';

  @override
  String get stopTracking => 'Stop tracking';

  @override
  String get sectionLastLocation => 'Last location';

  @override
  String get sectionActivityLog => 'Activity log';

  @override
  String logCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get waitingForLocation => 'Waiting for the first location…';

  @override
  String get noLocationYet => 'No location received yet.';

  @override
  String get noLogEntries => 'No entries.';

  @override
  String olderEntries(int count) {
    return '+$count older entries';
  }

  @override
  String get metricLatitude => 'Latitude';

  @override
  String get metricLongitude => 'Longitude';

  @override
  String get metricAccuracy => 'Accuracy';

  @override
  String get metricSpeed => 'Speed';

  @override
  String get metricAltitude => 'Altitude';

  @override
  String get metricTime => 'Time';

  @override
  String unitMeters(String value) {
    return '$value m';
  }

  @override
  String unitSpeed(String value) {
    return '$value km/h';
  }

  @override
  String locationSource(String provider) {
    return 'Source: $provider';
  }

  @override
  String get mockedLocation => 'Mock location';

  @override
  String get sessionStarted => 'Session started';

  @override
  String get sessionEnded => 'Session ended';

  @override
  String get settingsSummary =>
      'Interval 3 s  ·  Accuracy: Navigation  ·  Client: Android';

  @override
  String get permissionDenied => 'Location permission was not granted.';

  @override
  String get notificationChannelName => 'Location tracking';

  @override
  String get notificationTitle => 'Location tracking active';

  @override
  String get notificationMessage =>
      'Your location is being recorded in the background';

  @override
  String get notificationBigMessage =>
      'Background location is on so your route is recorded even when the app is closed.';

  @override
  String notificationLastUpdate(String time) {
    return 'Last update: $time';
  }
}
