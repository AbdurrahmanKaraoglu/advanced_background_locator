# Gson TypeToken için generic bilgileri koruma
-keepattributes Signature
-keepattributes *Annotation*



# TypeToken sınıfını koruma
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Gson kütüphanesini küçültme ve optimize etme
-keep class com.google.gson.** { *; }
