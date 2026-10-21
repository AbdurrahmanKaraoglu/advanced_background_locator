# Gson needs generic signatures to deserialize the stored init data map.
-keepattributes Signature
-keep class * extends com.google.gson.reflect.TypeToken
