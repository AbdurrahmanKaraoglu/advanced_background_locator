package com.abdurrahmankaraoglu.advanced_background_locator.provider

import java.util.HashMap

interface LocationUpdateListener {
    fun onLocationUpdated(location: HashMap<Any, Any>?)
}