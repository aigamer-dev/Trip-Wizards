## ProGuard rules generated from R8 missing rules
# Added to suppress warnings and keep necessary classes referenced by external libs

# R8 missing classes generated rules (from build/app/outputs/mapping/release/missing_rules.txt)
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# You can add additional -keep rules here if R8 removes classes required at runtime

# Keep Stripe push provisioning classes referenced by react-native-stripe SDK
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep react-native-stripe push provisioning proxy classes
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# ============================================================================
# Google Play Core - Required for Flutter deferred components
# ============================================================================
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Keep Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# ============================================================================
# Firebase Authentication - Critical for login functionality
# ============================================================================
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.firebase-auth-api.** { *; }
-keepclassmembers class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**

# Keep FirebaseAuth classes
-keep class com.google.firebase.auth.FirebaseAuth { *; }
-keep class com.google.firebase.auth.FirebaseUser { *; }
-keep class com.google.firebase.auth.FirebaseAuthException { *; }
-keep class com.google.firebase.auth.AuthResult { *; }

# ============================================================================
# Google Sign-In - Required for Google authentication
# ============================================================================
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Sign-In specific
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.identity.** { *; }
-keep interface com.google.android.gms.auth.api.signin.** { *; }

# ============================================================================
# Cloud Firestore - Keep all model classes
# ============================================================================
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# Keep all Firestore model classes (for serialization)
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Keep Firestore DocumentReference and CollectionReference
-keep class com.google.firebase.firestore.DocumentReference { *; }
-keep class com.google.firebase.firestore.CollectionReference { *; }
-keep class com.google.firebase.firestore.FirebaseFirestore { *; }

# ============================================================================
# Firebase Core
# ============================================================================
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.FirebaseOptions { *; }
-keepclassmembers class com.google.firebase.** { *; }

# ============================================================================
# Firebase Storage
# ============================================================================
-keep class com.google.firebase.storage.** { *; }
-keepclassmembers class com.google.firebase.storage.** { *; }
-dontwarn com.google.firebase.storage.**

# ============================================================================
# Firebase Messaging (Push Notifications)
# ============================================================================
-keep class com.google.firebase.messaging.** { *; }
-keepclassmembers class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# ============================================================================
# Google Play Services - Required for Google Sign-In
# ============================================================================
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Google Play Services Auth
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# ============================================================================
# Gson - JSON Serialization
# ============================================================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep generic signature of classes used with Gson
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================================================
# OkHttp - HTTP Client
# ============================================================================
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# ============================================================================
# Retrofit - REST API Client
# ============================================================================
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# ============================================================================
# Kotlin - Keep all Kotlin metadata
# ============================================================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.** {
    volatile <fields>;
}

# ============================================================================
# Flutter Specific
# ============================================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================================================
# General Rules - Keep line numbers for debugging
# ============================================================================
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================================================
# Flutter Plugin Specific - Critical for authentication plugins
# ============================================================================
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Keep all plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# ============================================================================
# Additional Firebase Auth Rules - More specific
# ============================================================================
# Keep all Firebase Auth internal classes
-keep class com.google.firebase.auth.internal.** { *; }
-keep class com.google.firebase.auth.api.** { *; }
-keep interface com.google.firebase.auth.** { *; }

# Keep GoogleAuthProvider and EmailAuthProvider
-keep class com.google.firebase.auth.GoogleAuthProvider { *; }
-keep class com.google.firebase.auth.EmailAuthProvider { *; }
-keep class com.google.firebase.auth.AuthCredential { *; }
-keep class com.google.firebase.auth.OAuthProvider { *; }

# ============================================================================
# Additional Google Sign-In Rules
# ============================================================================
# Keep Google Sign-In account classes
-keep class com.google.android.gms.auth.api.signin.GoogleSignInAccount { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInClient { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInOptions { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignInOptions$Builder { *; }

# Keep Google Auth API
-keep class com.google.android.gms.auth.GoogleAuthUtil { *; }
-keep class com.google.android.gms.auth.UserRecoverableAuthException { *; }

# ============================================================================
# Prevent obfuscation of method channels
# ============================================================================
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# ============================================================================
# Keep all R8 annotations
# ============================================================================
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault
