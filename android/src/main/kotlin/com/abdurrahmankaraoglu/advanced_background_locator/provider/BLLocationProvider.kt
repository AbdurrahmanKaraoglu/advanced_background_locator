package com.abdurrahmankaraoglu.advanced_background_locator.provider

interface BLLocationProvider {
    var listener: LocationUpdateListener?

    fun removeLocationUpdates()

    fun requestLocationUpdates(request: LocationRequestOptions)
}
