package abdurrahmankaraoglu.app.advanced_background_locator.provider


interface LocationUpdateListener {
    fun onLocationUpdated(location: Map<*, *>?)
}