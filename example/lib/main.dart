import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:advanced_background_locator/advanced_background_locator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'file_manager.dart';
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

// Dinleyici
    port.listen((dynamic data) async {
      if (data != null) {
        debugPrint('Data: $data');
        await updateUI(data);
      }
    }, onDone: () {
      debugPrint('Port closed.');
    }, onError: (error) {
      debugPrint('Error: $error');
    });

    initPlatformState();
  }

  Future<void> updateUI(dynamic data) async {
    final log = await FileManager.readLogFile();
    final LocationDto? locationDto = data is Map ? LocationDto.fromJson(data) : null;
    if (locationDto != null) {
      await _updateNotificationText(locationDto);
    }
    if (!mounted) return;

    setState(() {
      if (locationDto != null) {
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
    final log = await FileManager.readLogFile();
    final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
    if (!mounted) return;
    setState(() {
      logStr = log;
      isRunning = isRunningResp;
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(LocationServiceRepository.isolateName);
    port.close();
    super.dispose();
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
    if (!mounted) return;
    setState(() {
      isRunning = isRunningResp;
    });
  }

  Future<void> _onStart() async {
    if (await _checkLocationPermission()) {
      await _startLocator();
      final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
      if (!mounted) return;
      setState(() {
        isRunning = isRunningResp;
        lastLocation = null;
      });
    } else {
      // İzin reddedildi
    }
  }

  /// Requests foreground location first; background ("Allow all the time") must be
  /// requested separately on Android 11+ and iOS. Background access is optional:
  /// tracking still works while the foreground service notification is shown.
  Future<bool> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      return false;
    }

    // Android 13+: without this the foreground service notification is hidden.
    await Permission.notification.request();
    await Permission.locationAlways.request();
    return true;
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
        interval: 3,
        distanceFilter: 0,
        client: LocationClient.android,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Konum takibi',
          notificationTitle: 'Konum Takibini Başlat',
          notificationMsg: 'Arka planda konumu izle',
          notificationBigMsg: 'Uygulamayı konumunuzla güncel tutmak için arka plan konumu açık. Bu, uygulama çalışmıyorken ana özelliklerin düzgün çalışması için gereklidir.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
  }
}
