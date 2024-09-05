import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:advanced_background_locator/advanced_background_locator.dart';
import 'package:advanced_background_locator/location_dto.dart';
import 'package:advanced_background_locator/settings/android_settings.dart';
import 'package:advanced_background_locator/settings/ios_settings.dart';
import 'package:advanced_background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:location_permissions/location_permissions.dart';
import 'file_manager.dart';
import 'location_callback_handler.dart';
import 'location_service_repository.dart'; // Dosya yönetimi için

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ReceivePort port = ReceivePort();
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
      await updateUI(data);
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
    if (data == null) return;

    await AdvancedBackgroundLocator.updateNotificationText(title: "New Location Received", msg: "${DateTime.now()}", bigMsg: "${data.latitude}, ${data.longitude}");
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
          title: const Text('Flutter Background Locator'),
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onStart,
                    child: const Text('Start'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStop,
                    child: const Text('Stop'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Clear Log'),
                    onPressed: () {
                      FileManager.clearLogFile();
                      setState(() {
                        logStr = '';
                      });
                    },
                  ),
                ),
                Text("Status: ${isRunning != null ? (isRunning ? 'Is running' : 'Is not running') : "-"}"),
                Text(logStr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onStop() async {
    await AdvancedBackgroundLocator.unRegisterLocationUpdate();
    final isRunningResp = await AdvancedBackgroundLocator.isServiceRunning();
    setState(() {
      isRunning = isRunningResp;
    });
  }

  void _onStart() async {
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
    final access = await LocationPermissions().checkPermissionStatus();
    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );
        return permission == PermissionStatus.granted;
      case PermissionStatus.granted:
        return true;
      default:
        return false;
    }
  }

  Future<void> _startLocator() async {
    Map<String, dynamic> data = {'countInit': 1};
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
          notificationChannelName: 'Location Tracking',
          notificationTitle: 'Start Location Tracking',
          notificationMsg: 'Track location in background',
          notificationBigMsg: 'Background location is on to keep the app up-to-date with your location.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
  }
}
