package abdurrahmankaraoglu.app.advanced_background_locator.provider

import android.location.Location
import android.os.Build
import abdurrahmankaraoglu.app.advanced_background_locator.Keys
import com.google.android.gms.location.LocationResult

class LocationParserUtil {
    companion object {
        // Function to create a Map from Location
        private fun createLocationMap(location: Location): Map<String, Any> {
            val speedAccuracy = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                location.speedAccuracyMetersPerSecond
            } else {
                0f
            }

            val isMocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                location.isMock
            } else {
                @Suppress("DEPRECATION")
                location.isFromMockProvider
            }
            // Keys must match lib/keys.dart, numbers are sent as doubles to match LocationDto.
            val locationMap = mutableMapOf<String, Any>()
            locationMap[Keys.ARG_IS_MOCKED] = isMocked
            locationMap[Keys.ARG_LATITUDE] = location.latitude
            locationMap[Keys.ARG_LONGITUDE] = location.longitude
            locationMap[Keys.ARG_ACCURACY] = location.accuracy.toDouble()
            locationMap[Keys.ARG_ALTITUDE] = location.altitude
            locationMap[Keys.ARG_SPEED] = location.speed.toDouble()
            locationMap[Keys.ARG_SPEED_ACCURACY] = speedAccuracy.toDouble()
            locationMap[Keys.ARG_HEADING] = location.bearing.toDouble()
            locationMap[Keys.ARG_TIME] = location.time.toDouble()
            locationMap[Keys.ARG_PROVIDER] = location.provider ?: ""

            return locationMap
        }
        

        // Function to get a Map from Location
        fun getLocationMapFromLocation(location: Location): Map<String, Any>? {
            return createLocationMap(location)
        }

        // Function to get a Map from LocationResult
        fun getLocationMapFromLocationResult(locationResult: LocationResult?): Map<String, Any>? {
            val firstLocation = locationResult?.lastLocation ?: return null
            return createLocationMap(firstLocation)
        }
    }
}
