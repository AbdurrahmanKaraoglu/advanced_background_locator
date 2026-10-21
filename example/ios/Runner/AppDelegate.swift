import Flutter
import UIKit
import advanced_background_locator

// Registers plugins on the background isolate started by advanced_background_locator.
func registerPlugins(registry: FlutterPluginRegistry) {
  if !registry.hasPlugin("BackgroundLocatorPlugin") {
    GeneratedPluginRegistrant.register(with: registry)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    BackgroundLocatorPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
