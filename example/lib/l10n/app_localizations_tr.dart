// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Konum Takibi';

  @override
  String get appSubtitle => 'Arka plan konum servisi';

  @override
  String get clearLog => 'Kaydı temizle';

  @override
  String get statusActive => 'Takip aktif';

  @override
  String get statusInactive => 'Takip kapalı';

  @override
  String get statusActiveDescription =>
      'Uygulama arka plandayken de konum kaydediliyor.';

  @override
  String get statusInactiveDescription => 'Konum kaydı için takibi başlatın.';

  @override
  String get badgeLive => 'Canlı';

  @override
  String get badgeIdle => 'Pasif';

  @override
  String get startTracking => 'Takibi başlat';

  @override
  String get stopTracking => 'Takibi durdur';

  @override
  String get sectionLastLocation => 'Son konum';

  @override
  String get sectionActivityLog => 'Etkinlik kaydı';

  @override
  String logCount(int count) {
    return '$count kayıt';
  }

  @override
  String get waitingForLocation => 'İlk konum bekleniyor…';

  @override
  String get noLocationYet => 'Henüz konum alınmadı.';

  @override
  String get noLogEntries => 'Kayıt yok.';

  @override
  String olderEntries(int count) {
    return '+$count eski kayıt';
  }

  @override
  String get metricLatitude => 'Enlem';

  @override
  String get metricLongitude => 'Boylam';

  @override
  String get metricAccuracy => 'Doğruluk';

  @override
  String get metricSpeed => 'Hız';

  @override
  String get metricAltitude => 'Yükseklik';

  @override
  String get metricTime => 'Zaman';

  @override
  String unitMeters(String value) {
    return '$value m';
  }

  @override
  String unitSpeed(String value) {
    return '$value km/sa';
  }

  @override
  String locationSource(String provider) {
    return 'Kaynak: $provider';
  }

  @override
  String get mockedLocation => 'Sahte konum';

  @override
  String get sessionStarted => 'Oturum başladı';

  @override
  String get sessionEnded => 'Oturum bitti';

  @override
  String get settingsSummary =>
      'Aralık 3 sn  ·  Doğruluk: Navigasyon  ·  İstemci: Android';

  @override
  String get permissionDenied => 'Konum izni verilmedi.';

  @override
  String get notificationChannelName => 'Konum takibi';

  @override
  String get notificationTitle => 'Konum takibi aktif';

  @override
  String get notificationMessage => 'Konumunuz arka planda kaydediliyor';

  @override
  String get notificationBigMessage =>
      'Uygulama kapalıyken de rotanızın kaydedilmesi için arka plan konumu açık.';

  @override
  String notificationLastUpdate(String time) {
    return 'Son güncelleme: $time';
  }
}
