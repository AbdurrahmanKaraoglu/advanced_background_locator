package com.abdurrahmankaraoglu.advanced_background_locator

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ActivityCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.abdurrahmankaraoglu.advanced_background_locator.pluggables.DisposePluggable
import com.abdurrahmankaraoglu.advanced_background_locator.pluggables.InitPluggable
import com.abdurrahmankaraoglu.advanced_background_locator.pluggables.Pluggable
import com.abdurrahmankaraoglu.advanced_background_locator.provider.BLLocationProvider
import com.abdurrahmankaraoglu.advanced_background_locator.provider.GoogleLocationProviderClient
import com.abdurrahmankaraoglu.advanced_background_locator.provider.AndroidLocationProviderClient
import com.abdurrahmankaraoglu.advanced_background_locator.provider.PreferencesManager
import java.util.HashMap

class IsolateHolderService : MethodChannel.MethodCallHandler, LocationUpdateListener, Service() {

    companion object {
        const val ACTION_SHUTDOWN = "SHUTDOWN"
        const val ACTION_START = "START"
        const val ACTION_UPDATE_NOTIFICATION = "UPDATE_NOTIFICATION"

        private const val WAKELOCK_TAG = "IsolateHolderService::WAKE_LOCK"
        private const val NOTIFICATION_ID = 1

        var backgroundEngine: FlutterEngine? = null
        var isServiceRunning = false
        var isServiceInitialized = false

        fun getBinaryMessenger(context: Context?): BinaryMessenger? {
            return backgroundEngine?.dartExecutor?.binaryMessenger
                ?: context?.let {
                    backgroundEngine = FlutterEngine(it)
                    backgroundEngine?.dartExecutor?.binaryMessenger
                }
        }
    }

    private var notificationChannelName = "Flutter Locator Plugin"
    private var notificationTitle = "Start Location Tracking"
    private var notificationMsg = "Track location in background"
    private var notificationBigMsg = "Background location is on to keep the app up-to-date with your location. This is required for main features to work properly when the app is not running."
    private var notificationIconColor = 0
    private var icon = 0
    private var wakeLockTime = 60 * 60 * 1000L // 1 hour default wake lock time
    private var locatorClient: BLLocationProvider? = null
    private lateinit var backgroundChannel: MethodChannel
    private var context: Context? = null
    private var pluggables: ArrayList<Pluggable> = ArrayList()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, getNotification())
        startLocatorService()
    }

    private fun startLocatorService() {
        (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(wakeLockTime)
            }
        }
        pluggables.forEach {
            context?.let { it1 -> it.onServiceStart(it1) }
        }
    }

    private fun getNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                Keys.CHANNEL_ID, notificationChannelName, NotificationManager.IMPORTANCE_LOW
            )
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }

        val intent = Intent(this, getMainActivityClass())
        intent.action = Keys.NOTIFICATION_ACTION

        val pendingIntent = PendingIntent.getActivity(
            this, 1, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, Keys.CHANNEL_ID)
            .setContentTitle(notificationTitle)
            .setContentText(notificationMsg)
            .setStyle(NotificationCompat.BigTextStyle().bigText(notificationBigMsg))
            .setSmallIcon(icon)
            .setColor(notificationIconColor)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.e("IsolateHolderService", "onStartCommand => intent.action : ${intent?.action}")

        if (intent == null || !checkLocationPermissions()) {
            Log.e("IsolateHolderService", "Stopping service due to permission issues")
            stopSelf()
            return super.onStartCommand(intent, flags, startId)
        }

        when (intent?.action) {
            ACTION_SHUTDOWN -> {
                if (isServiceRunning) {
                    shutdownHolderService()
                }
            }
            ACTION_START -> {
                if (!isServiceRunning) {
                    startHolderService(intent)
                }
            }
            ACTION_UPDATE_NOTIFICATION -> {
                if (isServiceRunning) {
                    updateNotification(intent)
                }
            }
        }
        return START_STICKY
    }

    private fun checkLocationPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
               ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun startHolderService(intent: Intent) {
        Log.e("IsolateHolderService", "startHolderService")
        notificationChannelName = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME) ?: notificationChannelName
        notificationTitle = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE) ?: notificationTitle
        notificationMsg = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_MSG) ?: notificationMsg
        notificationBigMsg = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG) ?: notificationBigMsg
        icon = resources.getIdentifier(intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON) ?: "ic_launcher", "mipmap", packageName)
        notificationIconColor = intent.getLongExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR, 0).toInt()
        wakeLockTime = intent.getIntExtra(Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME, 60) * 60 * 1000L

        locatorClient = context?.let { getLocationClient(it) }
        locatorClient?.requestLocationUpdates(getLocationRequest(intent))

        if (intent.hasExtra(Keys.SETTINGS_INIT_PLUGGABLE)) pluggables.add(InitPluggable())
        if (intent.hasExtra(Keys.SETTINGS_DISPOSABLE_PLUGGABLE)) pluggables.add(DisposePluggable())

        startLocatorService()
    }

    private fun shutdownHolderService() {
        Log.e("IsolateHolderService", "shutdownHolderService")
        (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                if (isHeld) release()
            }
        }
        locatorClient?.removeLocationUpdates()
        stopForeground(true)
        stopSelf()
        pluggables.forEach { context?.let { it1 -> it.onServiceDispose(it1) } }
    }

    private fun updateNotification(intent: Intent) {
        Log.e("IsolateHolderService", "updateNotification")
        notificationTitle = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE) ?: notificationTitle
        notificationMsg = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_MSG) ?: notificationMsg
        notificationBigMsg = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG) ?: notificationBigMsg

        val notification = getNotification()
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(NOTIFICATION_ID, notification)
    }

    private fun getMainActivityClass(): Class<*>? {
        val packageName = packageName
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val className = launchIntent?.component?.className ?: return null

        return try {
            Class.forName(className)
        } catch (e: ClassNotFoundException) {
            e.printStackTrace()
            null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                Keys.METHOD_SERVICE_INITIALIZED -> isServiceRunning = true
                else -> result.notImplemented()
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e("IsolateHolderService", "Error handling method call", e)
            result.error("ERROR", e.localizedMessage, null)
        }
    }

    override fun onDestroy() {
        isServiceRunning = false
        super.onDestroy()
    }

    private fun getLocationClient(context: Context): BLLocationProvider {
        return when (PreferencesManager.getLocationClient(context)) {
            LocationClient.Google -> GoogleLocationProviderClient(context, this)
            LocationClient.Android -> AndroidLocationProviderClient(context, this)
        }
    }

    override fun onLocationUpdated(location: HashMap<Any, Any>?) {
        try {
            context?.let {
                // Handle location updates
            }
        } catch (e: Exception) {
            Log.e("IsolateHolderService", "Error processing location update", e)
        }
    }

    private fun getLocationRequest(intent: Intent): LocationRequest {
        val interval = intent.getLongExtra(Keys.SETTINGS_LOCATION_REQUEST_INTERVAL, 10000)
        val fastestInterval = intent.getLongExtra(Keys.SETTINGS_LOCATION_REQUEST_FASTEST_INTERVAL, 5000)
        return LocationRequest.create().apply {
            this.interval = interval
            this.fastestInterval = fastestInterval
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }
    }
}
