# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep enum com.dexterous.flutterlocalnotifications.** { *; }

# Gson requirements (used by flutter_local_notifications for persistence)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Preserve type signatures for all classes to prevent 'Missing type parameter'
-keepattributes Signature

# Keep GeneratedPluginRegistrant for AndroidAlarmManager reflection
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
