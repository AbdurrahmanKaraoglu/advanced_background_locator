import 'package:flutter/widgets.dart';

import 'advanced_background_locator.dart';

/// Stops location updates when the app leaves the foreground.
class AutoStopHandler extends WidgetsBindingObserver {
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        await AdvancedBackgroundLocator.unRegisterLocationUpdate();
      case AppLifecycleState.inactive:
      // Inactive is also reported for transient interruptions (calls, control center).
      case AppLifecycleState.resumed:
        break;
    }
  }
}
