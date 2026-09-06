# Flutter-specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Core, Auth, and Firestore rules
# These rules prevent code shrinking from removing essential classes used by Firebase via reflection.

# Firebase Core
-keep class com.google.firebase.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.firebase-auth.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepnames class com.google.android.gms.common.api.internal.GoogleApiManager

# Cloud Firestore
-keep class com.google.firebase.firestore.** { *; }
# Keep setter and getter methods for your data model classes.
# Replace 'com.horoma.DigitalShop.models.**' with your actual package name and models path.
-keep class com.horoma.DigitalShop.models.** { *; }
-keep public class * extends com.google.firebase.firestore.IgnoreExtraProperties {
    public <init>();
}
-keepnames class com.google.protobuf.** { *; }

# Required by GMS
-keep class com.google.android.gms.common.api.internal.TaskApiCall {
    <init>(...);
}

# Play Core rules
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
