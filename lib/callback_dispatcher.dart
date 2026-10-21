import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'keys.dart';
import 'location_dto.dart';

/// Entry point of the background isolate started by the native side.
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel backgroundChannel = MethodChannel(Keys.BACKGROUND_CHANNEL_ID);

  backgroundChannel.setMethodCallHandler(serializeCalls(handleBackgroundMethodCall));
  backgroundChannel.invokeMethod(Keys.METHOD_SERVICE_INITIALIZED);
}

/// Runs [handler] for one call at a time, in arrival order, so an async
/// `initCallback` finishes before the first location reaches the callback.
@visibleForTesting
Future<void> Function(MethodCall) serializeCalls(Future<void> Function(MethodCall) handler) {
  Future<void> previous = Future<void>.value();
  return (MethodCall call) {
    final Future<void> current = previous.then((_) => handler(call));
    // A failing callback must not block the calls queued after it.
    previous = current.catchError((Object _) {});
    return current;
  };
}

/// Dispatches a call from the native side to the user callback whose handle it carries.
@visibleForTesting
Future<void> handleBackgroundMethodCall(MethodCall call) async {
  final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>? ?? const {};

  switch (call.method) {
    case Keys.BCM_SEND_LOCATION:
      final Function? callback = _callbackFromHandle(args[Keys.ARG_CALLBACK]);
      final Object? location = args[Keys.ARG_LOCATION];
      if (callback != null && location is Map) {
        await callback(LocationDto.fromJson(location));
      }
    case Keys.BCM_NOTIFICATION_CLICK:
      await _callbackFromHandle(args[Keys.ARG_NOTIFICATION_CALLBACK])?.call();
    case Keys.BCM_INIT:
      final Function? initCallback = _callbackFromHandle(args[Keys.ARG_INIT_CALLBACK]);
      final Object? data = args[Keys.ARG_INIT_DATA_CALLBACK];
      // Platform maps arrive as Map<Object?, Object?>; the callback expects string keys.
      await initCallback?.call(data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
    case Keys.BCM_DISPOSE:
      await _callbackFromHandle(args[Keys.ARG_DISPOSE_CALLBACK])?.call();
  }
}

Function? _callbackFromHandle(Object? rawHandle) {
  if (rawHandle is! int || rawHandle == 0) {
    return null;
  }
  return PluginUtilities.getCallbackFromHandle(CallbackHandle.fromRawHandle(rawHandle));
}
