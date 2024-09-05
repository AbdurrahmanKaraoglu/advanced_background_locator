package com.abdurrahmankaraoglu.advanced_background_locator

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.abdurrahmankaraoglu.advanced_background_locator.provider.LocationClient

class PreferencesManager {
    companion object {
        private const val PREF_NAME = "advanced_background_locator"
        private const val SHARED_PREFS_KEY = "shared_preferences_key"

        // Genel SharedPreferences editörü oluşturma
        private fun getEditor(context: Context) =
            context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE).edit()

        // Genel SharedPreferences okuma
        private fun getPreferences(context: Context) =
            context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

        @JvmStatic
        fun saveCallbackDispatcher(context: Context, dispatcherHandle: Long) {
            getEditor(context)
                .putLong(Keys.ARG_CALLBACK_DISPATCHER, dispatcherHandle)
                .apply()
        }

        @JvmStatic
        fun saveSettings(context: Context, settings: Map<String, Any?>) {
            val editor = getEditor(context)

            settings[Keys.ARG_CALLBACK]?.let { callback ->
                editor.putLong(Keys.ARG_CALLBACK, (callback as Number).toLong())
            }

            settings[Keys.ARG_NOTIFICATION_CALLBACK]?.let { callback ->
                editor.putLong(Keys.ARG_NOTIFICATION_CALLBACK, (callback as Number).toLong())
            }

            editor.putString(Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME,
                settings[Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME] as? String)
            editor.putString(Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE,
                settings[Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE] as? String)
            editor.putString(Keys.SETTINGS_ANDROID_NOTIFICATION_MSG,
                settings[Keys.SETTINGS_ANDROID_NOTIFICATION_MSG] as? String)
            editor.putString(Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG,
                settings[Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG] as? String)
            editor.putString(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON,
                settings[Keys.SETTINGS_ANDROID_NOTIFICATION_ICON] as? String)
            editor.putLong(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR,
                (settings[Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR] as? Number)?.toLong() ?: 0L)
            editor.putInt(Keys.SETTINGS_INTERVAL, (settings[Keys.SETTINGS_INTERVAL] as? Number)?.toInt() ?: 0)
            editor.putInt(Keys.SETTINGS_ACCURACY, (settings[Keys.SETTINGS_ACCURACY] as? Number)?.toInt() ?: 0)
            editor.putFloat(Keys.SETTINGS_DISTANCE_FILTER, (settings[Keys.SETTINGS_DISTANCE_FILTER] as? Number)?.toFloat() ?: 0f)

            settings[Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME]?.let { wakeLockTime ->
                editor.putInt(Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME, (wakeLockTime as Number).toInt())
            }

            editor.putInt(Keys.SETTINGS_ANDROID_LOCATION_CLIENT, (settings[Keys.SETTINGS_ANDROID_LOCATION_CLIENT] as? Number)?.toInt() ?: 0)
            editor.apply()
        }

        @JvmStatic
        fun getSettings(context: Context): Map<String, Any?> {
            val prefs = getPreferences(context)
            val settings = mutableMapOf<String, Any?>()

            settings[Keys.ARG_CALLBACK_DISPATCHER] = prefs.getLong(Keys.ARG_CALLBACK_DISPATCHER, 0)
            settings[Keys.ARG_CALLBACK] = prefs.getLong(Keys.ARG_CALLBACK, 0)

            if (prefs.contains(Keys.ARG_NOTIFICATION_CALLBACK)) {
                settings[Keys.ARG_NOTIFICATION_CALLBACK] = prefs.getLong(Keys.ARG_NOTIFICATION_CALLBACK, 0)
            }

            settings[Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME] = prefs.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_CHANNEL_NAME, "")
            settings[Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE] = prefs.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_TITLE, "")
            settings[Keys.SETTINGS_ANDROID_NOTIFICATION_MSG] = prefs.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_MSG, "")
            settings[Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG] = prefs.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_BIG_MSG, "")
            settings[Keys.SETTINGS_ANDROID_NOTIFICATION_ICON] = prefs.getString(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON, "")
            settings[Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR] = prefs.getLong(Keys.SETTINGS_ANDROID_NOTIFICATION_ICON_COLOR, 0)
            settings[Keys.SETTINGS_INTERVAL] = prefs.getInt(Keys.SETTINGS_INTERVAL, 0)
            settings[Keys.SETTINGS_ACCURACY] = prefs.getInt(Keys.SETTINGS_ACCURACY, 0)
            settings[Keys.SETTINGS_DISTANCE_FILTER] = prefs.getFloat(Keys.SETTINGS_DISTANCE_FILTER, 0f).toDouble()

            if (prefs.contains(Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME)) {
                settings[Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME] = prefs.getInt(Keys.SETTINGS_ANDROID_WAKE_LOCK_TIME, 0)
            }

            settings[Keys.SETTINGS_ANDROID_LOCATION_CLIENT] = prefs.getInt(Keys.SETTINGS_ANDROID_LOCATION_CLIENT, 0)

            return settings
        }

        @JvmStatic
        fun getLocationClient(context: Context): LocationClient {
            val client = getPreferences(context).getInt(Keys.SETTINGS_ANDROID_LOCATION_CLIENT, 0)
            return LocationClient.fromInt(client) ?: LocationClient.Google
        }

        @JvmStatic
        fun setCallbackHandle(context: Context, key: String, handle: Long?) {
            getEditor(context).apply {
                if (handle == null) {
                    remove(key)
                } else {
                    putLong(key, handle)
                }
                apply()
            }
        }

        @JvmStatic
        fun setDataCallback(context: Context, key: String, data: Map<*, *>?) {
            getEditor(context).apply {
                if (data == null) {
                    remove(key)
                } else {
                    putString(key, Gson().toJson(data))
                }
                apply()
            }
        }

        @JvmStatic
        fun getCallbackHandle(context: Context, key: String): Long? {
            return getPreferences(context).takeIf { it.contains(key) }?.getLong(key, 0L)
        }

        @JvmStatic
        fun getDataCallback(context: Context, key: String): Map<*, *>? {
            val dataStr = getPreferences(context).getString(key, null) ?: return null
            val type = object : TypeToken<Map<*, *>>() {}.type
            return Gson().fromJson(dataStr, type)
        }
    }
}
