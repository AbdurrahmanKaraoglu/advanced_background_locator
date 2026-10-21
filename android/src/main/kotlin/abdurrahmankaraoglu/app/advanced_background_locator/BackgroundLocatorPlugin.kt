package abdurrahmankaraoglu.app.advanced_background_locator

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class BackgroundLocatorPlugin
    : MethodCallHandler, FlutterPlugin, PluginRegistry.NewIntentListener, ActivityAware {
    private var context: Context? = null
    private var channel: MethodChannel? = null
    private var activityBinding: ActivityPluginBinding? = null

    companion object {
        private const val TAG = "BackgroundLocatorPlugin"

        @JvmStatic
        private fun sendResultWithDelay(result: Result?, value: Boolean, delay: Long) {
            Handler(Looper.getMainLooper()).postDelayed({
                result?.success(value)
            }, delay)
        }

        @JvmStatic
        private fun registerLocator(context: Context,
                                    args: Map<Any, Any>,
                                    result: Result?) {
            if (!hasLocationPermission(context)) {
                result?.error("PERMISSION_DENIED",
                        "'registerLocationUpdate' requires the ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION permission.",
                        null)
                return
            }

            if (IsolateHolderService.isServiceRunning) {
                // The service is running already
                Log.d(TAG, "Locator service is already running")
                result?.success(true)
                return
            }

            val settings = args[Keys.ARG_SETTINGS] as? Map<*, *>
            val callbackHandle = (args[Keys.ARG_CALLBACK] as? Number)?.toLong()
            if (settings == null || callbackHandle == null) {
                result?.error("INVALID_ARGUMENTS", "Missing callback or settings.", null)
                return
            }

            Log.d(TAG, "start locator with ${PreferencesManager.getLocationClient(context)} client")

            // save setting to use it when device reboots
            PreferencesManager.saveSettings(context, args)

            PreferencesManager.setCallbackHandle(context, Keys.CALLBACK_HANDLE_KEY, callbackHandle)
            PreferencesManager.setCallbackHandle(context, Keys.NOTIFICATION_CALLBACK_HANDLE_KEY,
                    (args[Keys.ARG_NOTIFICATION_CALLBACK] as? Number)?.toLong())
            // Handles from a previous registration must not leak into this one.
            PreferencesManager.setCallbackHandle(context, Keys.INIT_CALLBACK_HANDLE_KEY,
                    (args[Keys.ARG_INIT_CALLBACK] as? Number)?.toLong())
            PreferencesManager.setDataCallback(context, Keys.INIT_DATA_CALLBACK_KEY,
                    args[Keys.ARG_INIT_DATA_CALLBACK] as? Map<*, *>)
            PreferencesManager.setCallbackHandle(context, Keys.DISPOSE_CALLBACK_HANDLE_KEY,
                    (args[Keys.ARG_DISPOSE_CALLBACK] as? Number)?.toLong())

            if (!startIsolateService(context, settings)) {
                result?.error("SERVICE_START_FAILED",
                        "Could not start the location foreground service. On Android 12+ it can only be started while the app is in the foreground.",
                        null)
                return
            }
            PreferencesManager.setTrackingEnabled(context, true)

            // We need to know when the service binded exactly, there is some delay between starting a
            // service and it's binding
            sendResultWithDelay(result, true, 1000)
        }

        @JvmStatic
        private fun startIsolateService(context: Context, settings: Map<*, *>): Boolean {
            Log.d(TAG, "startIsolateService")
            return try {
                ContextCompat.startForegroundService(context, buildStartIntent(context, settings))
                true
            } catch (e: IllegalStateException) {
                // ForegroundServiceStartNotAllowedException (Android 12+) extends IllegalStateException.
                Log.e(TAG, "Foreground service start not allowed", e)
                false
            } catch (e: SecurityException) {
                Log.e(TAG, "Foreground service start not permitted", e)
                false
            }
        }

        @JvmStatic
        private fun initializeService(context: Context, args: Map<Any, Any>) {
            val callbackHandle = (args[Keys.ARG_CALLBACK_DISPATCHER] as? Number)?.toLong() ?: return
            setCallbackDispatcherHandle(context, callbackHandle)
        }

        @JvmStatic
        private fun unRegisterPlugin(context: Context, result: Result?) {
            PreferencesManager.setTrackingEnabled(context, false)

            val service = IsolateHolderService.instance
            if (!IsolateHolderService.isServiceRunning || service == null) {
                // The service is not running
                Log.d(TAG, "Locator service is not running, nothing to stop")
                result?.success(true)
                return
            }

            // The service lives in this process, so stop it directly instead of sending another
            // start command that would have to be promoted to the foreground again.
            Log.d(TAG, "Shutting down locator service")
            service.shutdownHolderService()
            result?.success(true)
        }

        @JvmStatic
        private fun setCallbackDispatcherHandle(context: Context, handle: Long) {
            context.getSharedPreferences(Keys.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                    .edit()
                    .putLong(Keys.CALLBACK_DISPATCHER_HANDLE_KEY, handle)
                    .apply()
        }

        @JvmStatic
        fun registerAfterBoot(context: Context) {
            if (!PreferencesManager.isTrackingEnabled(context)) {
                // Tracking was stopped (or never started) before the reboot.
                return
            }

            // Starting a location foreground service without a visible activity needs the
            // background location permission (Android 10+) or it fails on Android 14+.
            if (!hasLocationPermission(context) || !hasBackgroundLocationPermission(context)) {
                Log.w(TAG, "Missing location permission, not restarting after boot")
                return
            }

            val args = PreferencesManager.getSettings(context)
            initializeService(context, args)

            val settings = args[Keys.ARG_SETTINGS] as Map<*, *>
            startIsolateService(context, settings)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = context
        if (context == null) {
            result.error("NOT_ATTACHED", "Plugin is not attached to an engine.", null)
            return
        }

        when (call.method) {
            Keys.METHOD_PLUGIN_INITIALIZE_SERVICE -> {
                val args: Map<Any, Any> = call.arguments() ?: emptyMap()

                // save callback dispatcher to use it when device reboots
                PreferencesManager.saveCallbackDispatcher(context, args)
                initializeService(context, args)
                result.success(true)
            }
            Keys.METHOD_PLUGIN_REGISTER_LOCATION_UPDATE -> {
                val args: Map<Any, Any> = call.arguments() ?: emptyMap()
                registerLocator(context, args, result)
            }
            Keys.METHOD_PLUGIN_UN_REGISTER_LOCATION_UPDATE -> unRegisterPlugin(context, result)
            Keys.METHOD_PLUGIN_IS_REGISTER_LOCATION_UPDATE,
            Keys.METHOD_PLUGIN_IS_SERVICE_RUNNING -> result.success(IsolateHolderService.isServiceRunning)
            Keys.METHOD_PLUGIN_UPDATE_NOTIFICATION -> {
                val service = IsolateHolderService.instance
                if (!IsolateHolderService.isServiceRunning || service == null) {
                    result.success(false)
                    return
                }

                val args: Map<Any, Any> = call.arguments() ?: emptyMap()
                service.updateNotification(
                        args[Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE] as? String,
                        args[Keys.SETTINGS_ANDROID_NOTIFICATION_MSG] as? String,
                        args[Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG] as? String)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, Keys.CHANNEL_ID).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?): Boolean {
        if (intent?.action != Keys.NOTIFICATION_ACTION) {
            // this is not our notification
            return false
        }

        val context = context ?: return true
        val notificationCallback = PreferencesManager.getCallbackHandle(
                context, Keys.NOTIFICATION_CALLBACK_HANDLE_KEY) ?: return true
        val binaryMessenger = IsolateHolderService.getBinaryMessenger() ?: return true

        val backgroundChannel = MethodChannel(binaryMessenger, Keys.BACKGROUND_CHANNEL_ID)
        Handler(Looper.getMainLooper()).post {
            backgroundChannel.invokeMethod(
                    Keys.BCM_NOTIFICATION_CLICK,
                    hashMapOf(Keys.ARG_NOTIFICATION_CALLBACK to notificationCallback)
            )
        }
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        // The activity may have been (re)created by a tap on the notification.
        handleNotificationIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }
}
