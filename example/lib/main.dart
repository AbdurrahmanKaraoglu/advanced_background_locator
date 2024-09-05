import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:advanced_background_locator/advanced_background_locator.dart';
import 'package:advanced_background_locator/location_dto.dart';
import 'package:advanced_background_locator/settings/android_settings.dart';
import 'package:advanced_background_locator/settings/ios_settings.dart';
import 'package:advanced_background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // location_permissions yerine
import '../file_manager.dart';
import 'location_callback_handler.dart';
import 'location_service_repository.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ReceivePort port = ReceivePort();
  String logStr = '';
  bool isRunning = false;
  LocationDto? lastLocation;

  @override
  void initState() {
    super.initState();

    // Arka planda çalışan izleyici için port kaydını kaldır
    if (IsolateNameServer.lookupPortByName(LocationServiceRepository.isolateName) != null) {
      IsolateNameServer.removePortNameMapping(LocationServiceRepository.isolateName);
    }

    // Yeni port kaydını oluştur
    IsolateNameServer.registerPortWithName(port.sendPort, LocationServiceRepository.isolateName);

    // Port dinleme
    port.listen((dynamic data) async {
      if (data != null) {
        debugPrint('Data: $data');
        await updateUI(data);
      }
    });

    initPlatformState();
  }

  Future<void> updateUI(dynamic data) async {
    final log = await FileManager.readLogFile();
    LocationDto? locationDto = (data != null) ? LocationDto.fromJson(data) : null;
    await _updateNotificationText(locationDto!);

    setState(() {
      if (data != null) {
        lastLocation = locationDto;
      }
      logStr = log;
    });
  }

  Future<void> _updateNotificationText(LocationDto data) async {
    await AdvancedBackgroundLocator.updateNotificationText(
      title: "Yeni Konum Alındı",
      msg: "${DateTime.now()}",
      bigMsg: "${data.latitude}, ${data.longitude}",
    );
  }

  Future<void> initPlatformState() async {
    await AdvancedBackgroundLocator.initialize();
    logStr = await FileManager.readLogFile();
    final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
    setState(() {
      isRunning = isRunningResp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Arkaplanda Konum Bulucu'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _onStart,
                  child: const Text('Başlat'),
                ),
                ElevatedButton(
                  onPressed: onStop,
                  child: const Text('Bitir'),
                ),
                ElevatedButton(
                  onPressed: () {
                    FileManager.clearLogFile();
                    setState(() {
                      logStr = '';
                    });
                  },
                  child: const Text('Log Dosyasını Temizle'),
                ),
                Text("Durum: ${isRunning ? 'Çalışıyor' : 'Durduruldu'}${lastLocation != null ? "\nSon Konum: ${lastLocation!.latitude}, ${lastLocation!.longitude}" : ""}"),
                Text(logStr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onStop() async {
    await AdvancedBackgroundLocator.unRegisterLocationUpdate();
    final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
    setState(() {
      isRunning = isRunningResp;
    });
  }

  Future<void> _onStart() async {
    if (await _checkLocationPermission()) {
      await _startLocator();
      final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
      setState(() {
        isRunning = isRunningResp;
        lastLocation = null;
      });
    } else {
      // İzin reddedildi
    }
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    return false;
  }

  Future<void> _startLocator() async {
    final data = {'countInit': 1};
    await AdvancedBackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: const IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 0,
        stopWithTerminate: true,
      ),
      autoStop: false,
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Konum Takibi',
          notificationTitle: 'Konum Takibini Başlat',
          notificationMsg: 'Arkaplanda konumu takip et',
          notificationBigMsg: 'Uygulamanın konumunuzla güncel kalmasını sağlamak için arka plan konumu açıktır.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
  }
}
