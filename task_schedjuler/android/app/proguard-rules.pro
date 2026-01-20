# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Gson (Required for flutter_local_notifications)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Flutter Timezone
-keep class com.simonlovell.fluttertimezone.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Generic Flutter Plugin Keep (Safety Net)
-keep public class io.flutter.plugins.** { *; }
