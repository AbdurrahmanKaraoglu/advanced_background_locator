package abdurrahmankaraoglu.app.advanced_background_locator

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import abdurrahmankaraoglu.app.advanced_background_locator.pluggables.DisposePluggable
import abdurrahmankaraoglu.app.advanced_background_locator.pluggables.InitPluggable
import abdurrahmankaraoglu.app.advanced_background_locator.pluggables.Pluggable
import abdurrahmankaraoglu.app.advanced_background_locator.provider.*


class IsolateHolderService : MethodChannel.MethodCallHandler, LocationUpdateListener, Service() {
    companion object {
        const val ACTION_SHUTDOWN = "SHUTDOWN"

        const val ACTION_START = "START"

        private const val TAG = "IsolateHolderService"

        private const val WAKELOCK_TAG = "IsolateHolderService::WAKE_LOCK"

        private const val NOTIFICATION_ID = 1

        // Gives the dispose callback time to run before the background isolate is torn down.
        private const val ENGINE_DESTROY_DELAY_MS = 2000L

        @JvmStatic
        var backgroundEngine: FlutterEngine? = null

        @JvmStatic
        @Volatile
        var isServiceRunning = false

        @JvmStatic
        @Volatile
        var isServiceInitialized = false

        /** The running service instance; the plugin lives in the same process. */
        @JvmStatic
        var instance: IsolateHolderService? = null
            private set

        fun getBinaryMessenger(): BinaryMessenger? = backgroundEngine?.dartExecutor?.binaryMessenger
    }

    private var notificationChannelName = "Flutter Locator Plugin"
    private var notificationTitle = "Start Location Tracking"
    private var notificationMsg = "Track location in background"
    private var notificationBigMsg =
        "Background location is on to keep the app up-tp-date with your location. This is required for main features to work properly when the app is not running."
    private var notificationIconColor = 0
    private var icon = 0
    private var wakeLockTime = 60 * 60 * 1000L // 1 hour default wake lock time
    private var wakeLock: PowerManager.WakeLock? = null
    private var locatorClient: BLLocationProvider? = null
    internal lateinit var backgroundChannel: MethodChannel
    private val pluggables: ArrayList<Pluggable> = ArrayList()

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        icon = resolveIcon(null)
        // startForeground must be called quickly after startForegroundService.
        promoteToForeground()
        startLocatorService(this)
    }

    private fun promoteToForeground(): Boolean {
        return try {
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            } else {
                0
            }
            ServiceCompat.startForeground(this, NOTIFICATION_ID, getNotification(), type)
            true
        } catch (e: Exception) {
            // SecurityException when the location permission was revoked, or
            // ForegroundServiceStartNotAllowedException when started from the background.
            Log.e(TAG, "Could not promote service to foreground", e)
            false
        }
    }

    private fun start() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(wakeLockTime)
            }

        // Starting Service as foreground with a notification prevent service from closing
        if (!promoteToForeground()) {
            shutdownHolderService()
            return
        }

        pluggables.forEach { it.onServiceStart(this) }
    }

    private fun getNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Notification channel is available in Android O and up
            val channel = NotificationChannel(
                Keys.CHANNEL_ID, notificationChannelName,
                NotificationManager.IMPORTANCE_LOW
            )

            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }

        val builder = NotificationCompat.Builder(this, Keys.CHANNEL_ID)
            .setContentTitle(notificationTitle)
            .setContentText(notificationMsg)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(notificationBigMsg)
            )
            .setSmallIcon(icon)
            .setColor(notificationIconColor)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setOnlyAlertOnce(true) // so when data is updated don't make sound and alert in android 8.0+
            .setOngoing(true)

        packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
            intent.action = Keys.NOTIFICATION_ACTION
            intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            builder.setContentIntent(
                PendingIntent.getActivity(
                    this, 1, intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
            )
        }

        return builder.build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand => intent.action : ${intent?.action}")
        if (intent == null) {
            // The system restarted the service after killing the process (START_STICKY).
            val settings = PreferencesManager.getSettings(this)[Keys.ARG_SETTINGS] as Map<*, *>
            if (!PreferencesManager.isTrackingEnabled(this) || !hasLocationPermission(this)) {
                Log.w(TAG, "Not restarting the locator service")
                shutdownHolderService()
                return START_NOT_STICKY
            }
            return onStartCommand(buildStartIntent(this, settings), flags, startId)
        }

        when (intent.action) {
            ACTION_SHUTDOWN -> shutdownHolderService()
            ACTION_START -> restartTracking(intent)
        }

        return START_STICKY
    }

    /** Starts tracking with the given start intent, replacing a running session. */
    internal fun restartTracking(intent: Intent) {
        if (isServiceRunning) {
            stopTracking()
        }
        isServiceRunning = true
        startHolderService(intent)
    }

    private fun startHolderService(intent: Intent) {
        Log.d(TAG, "startHolderService")
        notificationChannelName =
            intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME) ?: notificationChannelName
        notificationTitle =
            intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE) ?: notificationTitle
        notificationMsg = intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_MSG) ?: notificationMsg
        notificationBigMsg =
            intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG) ?: notificationBigMsg
        icon = resolveIcon(intent.getStringExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON))
        notificationIconColor =
            intent.getLongExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR, 0).toInt()
        wakeLockTime = intent.getIntExtra(Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME, 60) * 60 * 1000L

        locatorClient = getLocationClient(this).also {
            it.requestLocationUpdates(getLocationRequest(intent))
        }

        // Fill pluggable list
        pluggables.clear()
        if (intent.hasExtra(Keys.SETTINGS_INIT_PLUGGABLE)) {
            pluggables.add(InitPluggable())
        }

        if (intent.hasExtra(Keys.SETTINGS_DISPOSABLE_PLUGGABLE)) {
            pluggables.add(DisposePluggable())
        }

        start()
    }

    /** Looks the icon up in mipmap, then drawable, falling back to the app icon. */
    private fun resolveIcon(iconName: String?): Int {
        val name = if (iconName.isNullOrEmpty()) "ic_launcher" else iconName
        val mipmap = resources.getIdentifier(name, "mipmap", packageName)
        if (mipmap != 0) return mipmap
        val drawable = resources.getIdentifier(name, "drawable", packageName)
        if (drawable != 0) return drawable
        return applicationInfo.icon
    }

    /** Stops location updates and releases resources while keeping the service alive. */
    private fun stopTracking() {
        locatorClient?.removeLocationUpdates()
        locatorClient = null

        pluggables.forEach { it.onServiceDispose(this) }
        pluggables.clear()

        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    internal fun shutdownHolderService() {
        Log.d(TAG, "shutdownHolderService")
        isServiceRunning = false
        stopTracking()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    internal fun updateNotification(title: String?, msg: String?, bigMsg: String?) {
        Log.d(TAG, "updateNotification")
        title?.let { notificationTitle = it }
        msg?.let { notificationMsg = it }
        bigMsg?.let { notificationBigMsg = it }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, getNotification())
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Keys.METHOD_SERVICE_INITIALIZED -> {
                isServiceInitialized = true
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDestroy() {
        isServiceRunning = false
        stopTracking()
        if (instance === this) {
            instance = null
        }

        val engine = backgroundEngine
        Handler(Looper.getMainLooper()).postDelayed({
            // Only destroy the engine if no new service run has replaced it meanwhile.
            if (!isServiceRunning && backgroundEngine === engine) {
                engine?.destroy()
                backgroundEngine = null
                isServiceInitialized = false
            }
        }, ENGINE_DESTROY_DELAY_MS)

        super.onDestroy()
    }

    private fun getLocationClient(context: Context): BLLocationProvider {
        val client = PreferencesManager.getLocationClient(context)
        if (client == LocationClient.Google &&
            GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) != ConnectionResult.SUCCESS
        ) {
            // e.g. devices without Google Play services; the fused provider would never report.
            Log.w(TAG, "Google Play services unavailable, falling back to LocationManager")
            return AndroidLocationProviderClient(context, this)
        }
        return when (client) {
            LocationClient.Google -> GoogleLocationProviderClient(context, this)
            LocationClient.Android -> AndroidLocationProviderClient(context, this)
        }
    }

    override fun onLocationUpdated(location: Map<*, *>?) {
        if (location == null) return
        val callback = PreferencesManager.getCallbackHandle(this, Keys.CALLBACK_HANDLE_KEY) ?: return
        val binaryMessenger = getBinaryMessenger() ?: return

        val result: Map<String, Any> = hashMapOf(
            Keys.ARG_CALLBACK to callback,
            Keys.ARG_LOCATION to location
        )

        // Platform channel messages must be sent from the main thread.
        val backgroundChannel = MethodChannel(binaryMessenger, Keys.BACKGROUND_CHANNEL_ID)
        Handler(Looper.getMainLooper()).post {
            backgroundChannel.invokeMethod(Keys.BCM_SEND_LOCATION, result)
        }
    }
}
