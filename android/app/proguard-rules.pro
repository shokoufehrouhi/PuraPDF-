# google_mlkit_text_recognition ships a single TextRecognizer.initialize()
# that references every per-script recognizer class (Chinese/Japanese/
# Korean/Devanagari), but this app only depends on the base + Latin script
# module (see pubspec.yaml) - R8 fails the release build on the others as
# "missing classes" otherwise, since they genuinely aren't on the classpath.
# They're never actually invoked by this app's OCR calls (see
# lib/core/ocr/... and the doclens scan feature), so warning-suppression is
# correct here, not a real gap - R8 rules generated for this exact error at
# build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# WorkManager (pulled in transitively by one of the Google/ML Kit
# dependencies, not used directly by this app) crashed on first launch of
# a release build with "Failed to create an instance of
# androidx.work.impl.WorkDatabase" - R8 was stripping/renaming the Room-
# compiler-generated `_Impl` classes WorkDatabase loads via reflection.
# Room/WorkManager normally ship their own consumer ProGuard rules for
# exactly this, but they weren't enough here - keep the generated
# implementations and their Database/Dao/Entity annotations explicitly.
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Database class * { *; }
-keep @androidx.room.Entity class * { *; }
-keep @androidx.room.Dao class * { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public static <fields>;
}
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.**

# ML Kit's own component-discovery bootstrap (ComponentDiscovery, logged as
# "Invalid component registrar... Could not instantiate
# CommonComponentRegistrar/TextRegistrar: NoSuchMethodException <init>")
# instantiates these registrar classes via reflection at app startup, same
# failure mode as the WorkDatabase one above - R8 strips their zero-arg
# constructors since nothing calls `new CommonComponentRegistrar()`
# directly. When that registration silently fails, ML Kit's
# TextRecognizer has nothing to dispatch to, and the doclens scan
# feature's OCR call surfaces as a generic caught exception (this app's
# errorGeneric string, "Something went wrong. Please try again.") rather
# than a crash. Keeping the whole package sidesteps guessing at exactly
# which reflectively-loaded classes matter.
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
