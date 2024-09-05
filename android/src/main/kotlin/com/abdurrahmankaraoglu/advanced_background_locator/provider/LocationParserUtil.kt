package com.abdurrahmankaraoglu.advanced_background_locator.provider

import android.location.Location
import android.os.Build
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

            val isMocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                location.isFromMockProvider
            } else {
                false
            }
            val locationMap = mutableMapOf<String, Any>()
            locationMap["isMocked"] = isMocked
            locationMap["latitude"] = location.latitude
            locationMap["longitude"] = location.longitude
            locationMap["accuracy"] = location.accuracy
            locationMap["altitude"] = location.altitude
            locationMap["speed"] = location.speed
            locationMap["speedAccuracy"] = speedAccuracy
            locationMap["heading"] = location.bearing
            locationMap["time"] = location.time.toDouble()
            locationMap["provider"] = location.provider ?: ""

            return locationMap
        }
        

        // Function to get a Map from Location
        fun getLocationMapFromLocation(location: Location): Map<String, Any> {
            return createLocationMap(location)
        }

        // Function to get a Map from LocationResult
        fun getLocationMapFromLocationResult(locationResult: LocationResult?): Map<String, Any>? {
            val firstLocation = locationResult?.lastLocation ?: return null
            return createLocationMap(firstLocation)
        }
    }
}
