import 'package:flutter/material.dart';

import 'advanced_background_locator.dart';

class AutoStopHandler extends WidgetsBindingObserver {
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        await AdvancedBackgroundLocator.unRegisterLocationUpdate();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }
}
