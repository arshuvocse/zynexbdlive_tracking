# Retrofit / Gson / SignalR models must survive obfuscation.
-keep class com.zynexbd.livetracking.models.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn okhttp3.**
-dontwarn retrofit2.**
