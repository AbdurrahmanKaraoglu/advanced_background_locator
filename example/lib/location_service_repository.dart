import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:example/file_manager.dart';

class LocationServiceRepository {
  static final LocationServiceRepository _instance = LocationServiceRepository._();

  LocationServiceRepository._();

  factory LocationServiceRepository() {
    return _instance;
  }

  static const String isolateName = 'LocatorIsolate';

  int _count = -1;

  Future<void> init(Map<dynamic, dynamic> params) async {
    if (params.containsKey('countInit')) {
      dynamic tmpCount = params['countInit'];
      _count = (tmpCount is double)
          ? tmpCount.toInt()
          : (tmpCount is String)
              ? int.parse(tmpCount)
              : (tmpCount is int)
                  ? tmpCount
                  : -2;
    } else {
      _count = 0;
    }
    await setLogLabel("start");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> dispose() async {
    await setLogLabel("end");
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> callback(LocationDto locationDto) async {
    await setLogPosition(_count, locationDto);
    final SendPort? send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(locationDto.toJson());
    _count++;
  }

  static Future<void> setLogLabel(String label) async {
    final date = DateTime.now();
    await FileManager.writeToLogFile('------------\n$label: ${formatDateLog(date)}\n------------\n');
  }

  static Future<void> setLogPosition(int count, LocationDto data) async {
    final date = DateTime.now();
    await FileManager.writeToLogFile('$count : ${formatDateLog(date)} --> ${formatLog(data)} --- isMocked: ${data.isMocked}\n');
  }

  static double dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  static String formatDateLog(DateTime date) {
    return '${date.hour}:${date.minute}:${date.second}';
  }

  static String formatLog(LocationDto locationDto) {
    return '${dp(locationDto.latitude, 4)} ${dp(locationDto.longitude, 4)}';
  }
}
