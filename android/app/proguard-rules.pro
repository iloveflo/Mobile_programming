# Google ML Kit (Barcode Scanning, Text Recognition, Commons)
# Prevent R8 from stripping or obfuscating classes accessed via reflection / JNI in release builds.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode_bundled.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.photos.vision.barhopper.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_barcode_scanning.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.mlkit.**

# google_mlkit_text_recognition references optional script packages (Chinese, Devanagari, Japanese, Korean)
# that are not bundled when only Latin script is used.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
