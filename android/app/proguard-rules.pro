# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase generic
-keep class com.google.firebase.** { *; }

# Added for speech_to_text if needed
-keep class com.csdcorp.speech_to_text.** { *; }

# Mobile Scanner
-keep class ch.zhaw.photofact.** { *; }

# Keep line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable

# Play Core (ignore missing classes referenced by Flutter split loading)
-dontwarn com.google.android.play.core.**
