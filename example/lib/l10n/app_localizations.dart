import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Background location service'**
  String get appSubtitle;

  /// No description provided for @clearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get clearLog;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Tracking active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Tracking off'**
  String get statusInactive;

  /// No description provided for @statusActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Your location is recorded even when the app is in the background.'**
  String get statusActiveDescription;

  /// No description provided for @statusInactiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Start tracking to record your location.'**
  String get statusInactiveDescription;

  /// No description provided for @badgeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get badgeLive;

  /// No description provided for @badgeIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get badgeIdle;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get startTracking;

  /// No description provided for @stopTracking.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get stopTracking;

  /// No description provided for @sectionLastLocation.
  ///
  /// In en, this message translates to:
  /// **'Last location'**
  String get sectionLastLocation;

  /// No description provided for @sectionActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get sectionActivityLog;

  /// No description provided for @logCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String logCount(int count);

  /// No description provided for @waitingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first location…'**
  String get waitingForLocation;

  /// No description provided for @noLocationYet.
  ///
  /// In en, this message translates to:
  /// **'No location received yet.'**
  String get noLocationYet;

  /// No description provided for @noLogEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries.'**
  String get noLogEntries;

  /// No description provided for @olderEntries.
  ///
  /// In en, this message translates to:
  /// **'+{count} older entries'**
  String olderEntries(int count);

  /// No description provided for @metricLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get metricLatitude;

  /// No description provided for @metricLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get metricLongitude;

  /// No description provided for @metricAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get metricAccuracy;

  /// No description provided for @metricSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get metricSpeed;

  /// No description provided for @metricAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get metricAltitude;

  /// No description provided for @metricTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get metricTime;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String unitMeters(String value);

  /// No description provided for @unitSpeed.
  ///
  /// In en, this message translates to:
  /// **'{value} km/h'**
  String unitSpeed(String value);

  /// No description provided for @locationSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {provider}'**
  String locationSource(String provider);

  /// No description provided for @mockedLocation.
  ///
  /// In en, this message translates to:
  /// **'Mock location'**
  String get mockedLocation;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Session started'**
  String get sessionStarted;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get sessionEnded;

  /// No description provided for @settingsSummary.
  ///
  /// In en, this message translates to:
  /// **'Interval 3 s  ·  Accuracy: Navigation  ·  Client: Android'**
  String get settingsSummary;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not granted.'**
  String get permissionDenied;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Location tracking'**
  String get notificationChannelName;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location tracking active'**
  String get notificationTitle;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Your location is being recorded in the background'**
  String get notificationMessage;

  /// No description provided for @notificationBigMessage.
  ///
  /// In en, this message translates to:
  /// **'Background location is on so your route is recorded even when the app is closed.'**
  String get notificationBigMessage;

  /// No description provided for @notificationLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update: {time}'**
  String notificationLastUpdate(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
