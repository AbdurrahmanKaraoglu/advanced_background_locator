package com.abdurrahmankaraoglu.advanced_background_locator.provider

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import androidx.core.content.ContextCompat

class AndroidLocationProviderClient(
    context: Context,
    override var listener: LocationUpdateListener?
) : BLLocationProvider, LocationListener {

    private val client: LocationManager? =
        ContextCompat.getSystemService(context, LocationManager::class.java)

    private var overrideLocation: Boolean = false
    private var timeOfLastLocation: Long = 0L
    private var timeBetweenLocation: Long = 0L

    @SuppressLint("MissingPermission")
    override fun removeLocationUpdates() {
        client?.removeUpdates(this)
    }

    @SuppressLint("MissingPermission")
    override fun requestLocationUpdates(request: LocationRequestOptions) {
        timeBetweenLocation = request.interval

        client?.let { locationManager ->
            // Request updates for both GPS and network providers if enabled
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    request.interval,
                    request.distanceFilter,
                    this
                )
            }
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    request.interval,
                    request.distanceFilter,
                    this
                )
            }

            // Retrieve the last known location
            val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

            // Determine the best location to return
            val bestLocation = when {
                gpsLocation != null && networkLocation != null -> {
                    if (gpsLocation.time < networkLocation.time) networkLocation else gpsLocation
                }
                gpsLocation != null -> gpsLocation
                networkLocation != null -> networkLocation
                else -> null
            }

            // Notify the listener with the best location
            bestLocation?.let {
                onLocationChanged(it)
            }
        }
    }

    override fun onLocationChanged(location: Location) {
        overrideLocation = false

        // Validate location accuracy
        if (location.hasAccuracy()) {
            if (location.accuracy != 0.0f && !location.accuracy.isNaN() && location.accuracy.isFinite()) {
                overrideLocation = true
            }
        }

        // Check if enough time has passed or if we need to override location
        if (location.time - timeOfLastLocation >= timeBetweenLocation || overrideLocation) {
            timeOfLastLocation = location.time
            listener?.onLocationUpdated(LocationParserUtil.getLocationMapFromLocation(location))
        }
    }

    override fun onProviderDisabled(provider: String) {
        // Optionally handle provider being disabled
    }

    override fun onProviderEnabled(provider: String) {
        // Optionally handle provider being enabled
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        // Optionally handle status changes
    }
}