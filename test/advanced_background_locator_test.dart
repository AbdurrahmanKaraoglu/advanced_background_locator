import 'dart:ui';

import 'package:advanced_background_locator/advanced_background_locator.dart';
import 'package:advanced_background_locator/callback_dispatcher.dart';
import 'package:advanced_background_locator/keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final List<Object?> received = [];

@pragma('vm:entry-point')
void onLocation(LocationDto location) => received.add(location);

@pragma('vm:entry-point')
void onInit(Map<String, dynamic> data) => received.add(data);

@pragma('vm:entry-point')
void onDispose() => received.add('dispose');

@pragma('vm:entry-point')
void onNotificationTap() => received.add('tap');

int rawHandle(Function f) => PluginUtilities.getCallbackHandle(f)!.toRawHandle();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(Keys.CHANNEL_ID);
  final List<MethodCall> calls = [];
  Object? Function(MethodCall call) reply = (_) => null;

  setUp(() {
    calls.clear();
    received.clear();
    reply = (_) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('LocationDto', () {
    test('parses an Android location map', () {
      final dto = LocationDto.fromJson({
        Keys.ARG_LATITUDE: 41.0,
        Keys.ARG_LONGITUDE: 29.0,
        Keys.ARG_ACCURACY: 5.5,
        Keys.ARG_ALTITUDE: 100.0,
        Keys.ARG_SPEED: 1.2,
        Keys.ARG_SPEED_ACCURACY: 0.3,
        Keys.ARG_HEADING: 90.0,
        Keys.ARG_TIME: 1700000000000.0,
        Keys.ARG_IS_MOCKED: true,
        Keys.ARG_PROVIDER: 'fused',
      });

      expect(dto.latitude, 41.0);
      expect(dto.longitude, 29.0);
      expect(dto.speedAccuracy, 0.3);
      expect(dto.isMocked, isTrue);
      expect(dto.provider, 'fused');
    });

    test('accepts ints and tolerates missing optional fields', () {
      final dto = LocationDto.fromJson(<Object?, Object?>{
        Keys.ARG_LATITUDE: 41,
        Keys.ARG_LONGITUDE: 29,
        Keys.ARG_ACCURACY: 5,
        Keys.ARG_ALTITUDE: 0,
        Keys.ARG_SPEED: 0,
        Keys.ARG_HEADING: -1,
        Keys.ARG_TIME: 1700000000000,
      });

      expect(dto.latitude, 41.0);
      expect(dto.time, 1700000000000.0);
      expect(dto.speedAccuracy, 0.0);
      expect(dto.isMocked, isFalse);
      expect(dto.provider, '');
    });

    test('toJson round-trips', () {
      final dto = LocationDto.fromJson({
        Keys.ARG_LATITUDE: 1.5,
        Keys.ARG_LONGITUDE: 2.5,
        Keys.ARG_IS_MOCKED: false,
        Keys.ARG_PROVIDER: 'gps',
      });

      expect(LocationDto.fromJson(dto.toJson()).toJson(), dto.toJson());
    });
  });

  group('AdvancedBackgroundLocator', () {
    test('initialize sends the callback dispatcher handle', () async {
      await AdvancedBackgroundLocator.initialize();

      expect(calls.single.method, Keys.METHOD_PLUGIN_INITIALIZE_SERVICE);
      expect(calls.single.arguments, {Keys.ARG_CALLBACK_DISPATCHER: rawHandle(callbackDispatcher)});
    });

    test('registerLocationUpdate sends Android settings under the settings key', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await AdvancedBackgroundLocator.registerLocationUpdate(
        onLocation,
        initCallback: onInit,
        initDataCallback: const {'countInit': 1},
        disposeCallback: onDispose,
        androidSettings: const AndroidSettings(
          interval: 3,
          distanceFilter: 10,
          client: LocationClient.android,
          androidNotificationSettings: AndroidNotificationSettings(
            notificationTitle: 'title',
            notificationIconColor: Colors.red,
            notificationTapCallback: onNotificationTap,
          ),
        ),
      );

      final call = calls.single;
      expect(call.method, Keys.METHOD_PLUGIN_REGISTER_LOCATION_UPDATE);
      final args = call.arguments as Map;
      expect(args[Keys.ARG_CALLBACK], rawHandle(onLocation));
      expect(args[Keys.ARG_INIT_CALLBACK], rawHandle(onInit));
      expect(args[Keys.ARG_DISPOSE_CALLBACK], rawHandle(onDispose));
      expect(args[Keys.ARG_NOTIFICATION_CALLBACK], rawHandle(onNotificationTap));
      expect(args[Keys.ARG_INIT_DATA_CALLBACK], {'countInit': 1});

      final settings = args[Keys.ARG_SETTINGS] as Map;
      expect(settings[Keys.SETTINGS_INTERVAL], 3);
      expect(settings[Keys.SETTINGS_DISTANCE_FILTER], 10.0);
      expect(settings[Keys.SETTINGS_ACCURACY], LocationAccuracy.NAVIGATION.value);
      expect(settings[Keys.SETTINGS_ANDROID_LOCATION_CLIENT], LocationClient.android.index);
      expect(settings[Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE], 'title');
      expect(settings[Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR], Colors.red.toARGB32());
    });

    test('registerLocationUpdate sends iOS settings at the top level', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await AdvancedBackgroundLocator.registerLocationUpdate(
        onLocation,
        iosSettings: const IOSSettings(accuracy: LocationAccuracy.HIGH, distanceFilter: 5, stopWithTerminate: true),
      );

      final args = calls.single.arguments as Map;
      expect(args.containsKey(Keys.ARG_SETTINGS), isFalse);
      expect(args[Keys.SETTINGS_ACCURACY], LocationAccuracy.HIGH.value);
      expect(args[Keys.SETTINGS_DISTANCE_FILTER], 5.0);
      expect(args[Keys.SETTINGS_IOS_STOP_WITH_TERMINATE], isTrue);
      expect(args[Keys.SETTINGS_IOS_SHOWS_BACKGROUND_LOCATION_INDICATOR], isFalse);
    });

    test('registerLocationUpdate rejects closures', () async {
      expect(
        () => AdvancedBackgroundLocator.registerLocationUpdate((_) {}),
        throwsArgumentError,
      );
      expect(calls, isEmpty);
    });

    test('registerLocationUpdate surfaces native errors', () async {
      reply = (_) => throw PlatformException(code: 'NOT_INITIALIZED');

      await expectLater(
        AdvancedBackgroundLocator.registerLocationUpdate(onLocation),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'NOT_INITIALIZED')),
      );
    });

    test('isServiceRunning and isRegisterLocationUpdate handle null replies', () async {
      expect(await AdvancedBackgroundLocator.isServiceRunning(), isFalse);
      expect(await AdvancedBackgroundLocator.isRegisterLocationUpdate(), isFalse);

      reply = (_) => true;
      expect(await AdvancedBackgroundLocator.isServiceRunning(), isTrue);
      expect(calls.map((c) => c.method), [
        Keys.METHOD_PLUGIN_IS_SERVICE_RUNNING,
        Keys.METHOD_PLUGIN_IS_REGISTER_LOCATION_UPDATE,
        Keys.METHOD_PLUGIN_IS_SERVICE_RUNNING,
      ]);
    });

    test('updateNotificationText only sends given values', () async {
      await AdvancedBackgroundLocator.updateNotificationText(title: 't', bigMsg: 'b');

      expect(calls.single.method, Keys.METHOD_PLUGIN_UPDATE_NOTIFICATION);
      expect(calls.single.arguments, {
        Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE: 't',
        Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG: 'b',
      });
    });

    test('unRegisterLocationUpdate invokes the native method', () async {
      await AdvancedBackgroundLocator.unRegisterLocationUpdate();
      expect(calls.single.method, Keys.METHOD_PLUGIN_UN_REGISTER_LOCATION_UPDATE);
    });

    testWidgets('autoStop stops updates when the app is paused', (tester) async {
      await AdvancedBackgroundLocator.registerLocationUpdate(onLocation, autoStop: true);
      calls.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(calls, isEmpty);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      // Unregistering removes the observer, so only one stop call is made.
      expect(calls.map((c) => c.method), [Keys.METHOD_PLUGIN_UN_REGISTER_LOCATION_UPDATE]);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  group('callback dispatcher', () {
    test('delivers locations to the registered callback', () async {
      await handleBackgroundMethodCall(MethodCall(Keys.BCM_SEND_LOCATION, <Object?, Object?>{
        Keys.ARG_CALLBACK: rawHandle(onLocation),
        Keys.ARG_LOCATION: <Object?, Object?>{Keys.ARG_LATITUDE: 1.0, Keys.ARG_LONGITUDE: 2.0},
      }));

      final dto = received.single as LocationDto;
      expect(dto.latitude, 1.0);
      expect(dto.longitude, 2.0);
    });

    test('passes init data with string keys', () async {
      await handleBackgroundMethodCall(MethodCall(Keys.BCM_INIT, <Object?, Object?>{
        Keys.ARG_INIT_CALLBACK: rawHandle(onInit),
        Keys.ARG_INIT_DATA_CALLBACK: <Object?, Object?>{'countInit': 1.0},
      }));

      expect(received.single, {'countInit': 1.0});
      expect(received.single, isA<Map<String, dynamic>>());
    });

    test('calls dispose and notification callbacks', () async {
      await handleBackgroundMethodCall(MethodCall(Keys.BCM_DISPOSE, {Keys.ARG_DISPOSE_CALLBACK: rawHandle(onDispose)}));
      await handleBackgroundMethodCall(MethodCall(Keys.BCM_NOTIFICATION_CLICK, {Keys.ARG_NOTIFICATION_CALLBACK: rawHandle(onNotificationTap)}));

      expect(received, ['dispose', 'tap']);
    });

    test('serializeCalls runs calls one at a time in order', () async {
      final List<String> order = [];
      final handler = serializeCalls((call) async {
        order.add('start ${call.method}');
        if (call.method == 'init') {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        if (call.method == 'fail') {
          throw StateError('boom');
        }
        order.add('end ${call.method}');
      });

      final init = handler(const MethodCall('init'));
      final failing = handler(const MethodCall('fail'));
      final location = handler(const MethodCall('location'));

      await init;
      await expectLater(failing, throwsStateError);
      await location;
      expect(order, ['start init', 'end init', 'start fail', 'start location', 'end location']);
    });

    test('ignores missing or empty callback handles', () async {
      await handleBackgroundMethodCall(const MethodCall(Keys.BCM_NOTIFICATION_CLICK, <Object?, Object?>{}));
      await handleBackgroundMethodCall(const MethodCall(Keys.BCM_DISPOSE, {Keys.ARG_DISPOSE_CALLBACK: 0}));
      await handleBackgroundMethodCall(const MethodCall(Keys.BCM_INIT, {Keys.ARG_INIT_CALLBACK: 0, Keys.ARG_INIT_DATA_CALLBACK: null}));
      await handleBackgroundMethodCall(const MethodCall(Keys.BCM_SEND_LOCATION));

      expect(received, isEmpty);
    });
  });
}
