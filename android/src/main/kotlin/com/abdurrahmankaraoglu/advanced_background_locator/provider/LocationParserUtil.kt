package com.abdurrahmankaraoglu.advanced_background_locator.provider

import android.location.Location
import android.os.Build
import com.google.android.gms.location.LocationResult
import com.abdurrahmankaraoglu.advanced_background_locator.Keys

// Data class for location information
data class LocationInfo(
    val isMocked: Boolean,
    val latitude: Double,
    val longitude: Double,
    val accuracy: Float,
    val altitude: Double,
    val speed: Float,
    val speedAccuracy: Float,
    val heading: Float,
    val time: Double,
    val provider: String?
)

class LocationParserUtil {
    companion object {
        // Function to create LocationInfo from Location
        private fun createLocationInfo(location: Location): LocationInfo {
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

            return LocationInfo(
                isMocked = isMocked,
                latitude = location.latitude,
                longitude = location.longitude,
                accuracy = location.accuracy,
                altitude = location.altitude,
                speed = location.speed,
                speedAccuracy = speedAccuracy,
                heading = location.bearing,
                time = location.time.toDouble(),
                provider = location.provider
            )
        }

        // Function to get LocationInfo from Location
        fun getLocationInfoFromLocation(location: Location): LocationInfo {
            return createLocationInfo(location)
        }

        // Function to get LocationInfo from LocationResult
        fun getLocationInfoFromLocationResult(locationResult: LocationResult?): LocationInfo? {
            val firstLocation = locationResult?.lastLocation ?: return null
            return createLocationInfo(firstLocation)
        }
    }
}
