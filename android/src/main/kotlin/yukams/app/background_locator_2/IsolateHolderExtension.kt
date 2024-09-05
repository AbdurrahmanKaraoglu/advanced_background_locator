package com.abdurrahmankaraoglu.advanced_background_locator

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.abdurrahmankaraoglu.advanced_background_locator.Keys

class IsolateHolderService : Service(), MethodCallHandler {

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_SHUTDOWN = "ACTION_SHUTDOWN"
        const val ACTION_UPDATE_NOTIFICATION = "ACTION_UPDATE_NOTIFICATION"
        var isServiceRunning = false
    }

    private lateinit var flutterEngine: FlutterEngine
    private var methodChannel: MethodChannel? = null

    override fun onCreate() {
        super.onCreate()
        flutterEngine = FlutterEngine(applicationContext).apply {
            dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            FlutterEngineCache.getInstance().put("service_engine", this)
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Keys.CHANNEL_ID)
            methodChannel?.setMethodCallHandler(this@IsolateHolderService)
        }
        isServiceRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            when (it.action) {
                ACTION_START -> startLocatorService(it)
                ACTION_SHUTDOWN -> stopLocatorService()
                ACTION_UPDATE_NOTIFICATION -> updateNotification(it)
            }
        }
        return START_STICKY
    }

    private fun startLocatorService(intent: Intent) {
        Log.d("IsolateHolderService", "Starting locator service")
        val settings = intent.extras
        val notification = createNotification(settings)
        startForeground(1, notification)
    }

    private fun stopLocatorService() {
        Log.d("IsolateHolderService", "Stopping locator service")
        stopForeground(true)
        stopSelf()
        isServiceRunning = false
    }

    private fun updateNotification(intent: Intent) {
        val notification = createNotification(intent.extras)
        startForeground(1, notification)
    }

    private fun createNotification(extras: Bundle?): Notification {
        val channelId = "background_locator_channel"
        val notificationManager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Background Locator Service", NotificationManager.IMPORTANCE_LOW)
            notificationManager.createNotificationChannel(channel)
        }
        val builder = Notification.Builder(this, channelId)
            .setContentTitle(extras?.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE))
            .setContentText(extras?.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_MSG))
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(Notification.PRIORITY_LOW)
        return builder.build()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "methodName" -> result.success(true) // Handle method call here
            else -> result.notImplemented()
        }
    }
}
