package com.abdurrahmankaraoglu.trackerapp

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import com.abdurrahmankaraoglu.advanced_background_locator.AdvancedBackgroundLocatorPlugin // Buradaki paket adını kontrol edin

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        // Plugin kaydını burada yapın
    }

    override fun registerWith(registry: PluginRegistry?) {
        AdvancedBackgroundLocatorPlugin.registerWith(registry?.registrarFor("com.abdurrahmankaraoglu.advanced_background_locator.AdvancedBackgroundLocatorPlugin"))
    }
}
