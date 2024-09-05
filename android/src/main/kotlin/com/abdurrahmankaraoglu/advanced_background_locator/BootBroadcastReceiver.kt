package com.abdurrahmankaraoglu.advanced_background_locator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            BackgroundLocatorPlugin.registerAfterBoot(context)
        }
    }
}
