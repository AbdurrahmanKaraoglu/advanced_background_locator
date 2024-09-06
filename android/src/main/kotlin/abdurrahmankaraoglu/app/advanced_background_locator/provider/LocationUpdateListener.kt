package abdurrahmankaraoglu.app.advanced_background_locator.provider

import java.util.HashMap

interface LocationUpdateListener {
    fun onLocationUpdated(location: Map<*, *>?)
}