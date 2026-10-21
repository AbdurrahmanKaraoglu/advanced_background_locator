package abdurrahmankaraoglu.app.advanced_background_locator

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Priority
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import abdurrahmankaraoglu.app.advanced_background_locator.IsolateHolderService.Companion.isServiceInitialized
import abdurrahmankaraoglu.app.advanced_background_locator.provider.LocationRequestOptions

internal fun IsolateHolderService.startLocatorService(context: Context) {
    // prevent multiple background engines when the service is recreated quickly
    synchronized(IsolateHolderService::class.java) {
        if (!hasLocationPermission(context)) {
            return
        }

        // resetting the background engine to avoid being stuck after an app crash
        IsolateHolderService.backgroundEngine?.destroy()
        IsolateHolderService.backgroundEngine = null
        isServiceInitialized = false

        try {
            // We need flutter engine to handle callback, so if it is not available we have to create a
            // Flutter engine without any view. Creating it also loads the Flutter native library,
            // which the callback lookup below needs.
            val engine = FlutterEngine(context)

            val callbackHandle = context.getSharedPreferences(
                Keys.SHARED_PREFERENCES_KEY,
                Context.MODE_PRIVATE
            )
                .getLong(Keys.CALLBACK_DISPATCHER_HANDLE_KEY, 0)
            val callbackInfo =
                FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)

            if (callbackInfo == null) {
                Log.e("IsolateHolderExtension", "Fatal: failed to find callback, was AdvancedBackgroundLocator.initialize() called?")
                engine.destroy()
                return
            }

            val args = DartExecutor.DartCallback(
                context.assets,
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                callbackInfo
            )
            engine.dartExecutor.executeDartCallback(args)
            IsolateHolderService.backgroundEngine = engine

            backgroundChannel = MethodChannel(
                engine.dartExecutor.binaryMessenger,
                Keys.BACKGROUND_CHANNEL_ID
            )
            backgroundChannel.setMethodCallHandler(this)
        } catch (e: UnsatisfiedLinkError) {
            Log.e("IsolateHolderExtension", "Could not start background engine", e)
        }
    }
}

internal fun hasLocationPermission(context: Context): Boolean {
    return ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
}

internal fun hasBackgroundLocationPermission(context: Context): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
        return true
    }
    return ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
}

/** Builds the [IsolateHolderService.ACTION_START] intent from the settings map sent by Dart. */
internal fun buildStartIntent(context: Context, settings: Map<*, *>): Intent {
    val intent = Intent(context, IsolateHolderService::class.java)
    intent.action = IsolateHolderService.ACTION_START

    listOf(
        Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME,
        Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE,
        Keys.SETTINGS_ANDROID_NOTIFICATION_MSG,
        Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG,
        Keys.SETTINGS_ANDROID_NOTIFICATION_ICON
    ).forEach { key ->
        (settings[key] as? String)?.let { intent.putExtra(key, it) }
    }

    // The standard codec sends Dart ints as Integer or Long depending on their size.
    (settings[Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR] as? Number)?.let {
        intent.putExtra(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR, it.toLong())
    }
    (settings[Keys.SETTINGS_INTERVAL] as? Number)?.let {
        intent.putExtra(Keys.SETTINGS_INTERVAL, it.toInt())
    }
    (settings[Keys.SETTINGS_ACCURACY] as? Number)?.let {
        intent.putExtra(Keys.SETTINGS_ACCURACY, it.toInt())
    }
    (settings[Keys.SETTINGS_DISTANCE_FILTER] as? Number)?.let {
        intent.putExtra(Keys.SETTINGS_DISTANCE_FILTER, it.toDouble())
    }
    (settings[Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME] as? Number)?.let {
        intent.putExtra(Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME, it.toInt())
    }

    if (PreferencesManager.getCallbackHandle(context, Keys.INIT_CALLBACK_HANDLE_KEY) != null) {
        intent.putExtra(Keys.SETTINGS_INIT_PLUGGABLE, true)
    }
    if (PreferencesManager.getCallbackHandle(context, Keys.DISPOSE_CALLBACK_HANDLE_KEY) != null) {
        intent.putExtra(Keys.SETTINGS_DISPOSABLE_PLUGGABLE, true)
    }

    return intent
}

fun getLocationRequest(intent: Intent): LocationRequestOptions {
    val interval: Long = (intent.getIntExtra(Keys.SETTINGS_INTERVAL, 10) * 1000).toLong()
    val accuracyKey = intent.getIntExtra(Keys.SETTINGS_ACCURACY, 4)
    val accuracy = getAccuracy(accuracyKey)
    val distanceFilter = intent.getDoubleExtra(Keys.SETTINGS_DISTANCE_FILTER, 0.0)

    return LocationRequestOptions(interval, accuracy, distanceFilter.toFloat())
}

fun getAccuracy(key: Int): Int {
    return when (key) {
        0 -> Priority.PRIORITY_PASSIVE
        1 -> Priority.PRIORITY_LOW_POWER
        2 -> Priority.PRIORITY_BALANCED_POWER_ACCURACY
        3 -> Priority.PRIORITY_HIGH_ACCURACY
        4 -> Priority.PRIORITY_HIGH_ACCURACY
        else -> Priority.PRIORITY_HIGH_ACCURACY
    }
}
