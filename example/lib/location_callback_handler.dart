import 'dart:async';

import 'package:advanced_background_locator/location_dto.dart';
import 'package:example/location_service_repository.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
class LocationCallbackHandler {
  @pragma('vm:entry-point')
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    debugPrint('***initCallback');
    LocationServiceRepository myLocationCallbackRepository = LocationServiceRepository();
    await myLocationCallbackRepository.init(params);
  }

  @pragma('vm:entry-point')
  static Future<void> disposeCallback() async {
    LocationServiceRepository myLocationCallbackRepository = LocationServiceRepository();
    debugPrint('***disposeCallback');
    await myLocationCallbackRepository.dispose();
  }

  @pragma('vm:entry-point')
  static Future<void> callback(LocationDto locationDto) async {
    LocationServiceRepository myLocationCallbackRepository = LocationServiceRepository();
    debugPrint('***callback');
    await myLocationCallbackRepository.callback(locationDto);
  }

  @pragma('vm:entry-point')
  static Future<void> notificationCallback() async {
    debugPrint('***notificationCallback');
  }
}
