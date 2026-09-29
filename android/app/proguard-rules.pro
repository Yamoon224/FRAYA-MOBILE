# Regles ProGuard/R8 pour les builds release minifies (-Pminify=true).
#
# Le plugin Gradle Flutter injecte deja ses propres regles pour le moteur Flutter et
# io.flutter.*. Ce fichier ne couvre que les SDK natifs sensibles a la reflexion, que R8
# supprimerait sans le savoir : la compilation reste verte, mais le crash arrive au runtime.

# --- OneSignal (notifications push) -----------------------------------------
# Le SDK instancie ses receivers/services par nom de classe.
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# --- Firebase / Crashlytics --------------------------------------------------
# Les modeles Firestore/RTDB sont deserialises par reflexion, et Crashlytics a besoin
# des numeros de ligne + du nom des fichiers source pour desobfusquer les stack traces.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- Google Maps -------------------------------------------------------------
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# --- Divers ------------------------------------------------------------------
# Classes referencees uniquement depuis le manifest (Application, services, receivers).
-keep class com.carrementweb.fraya_mobile.** { *; }

# Enums : values()/valueOf() sont appeles par reflexion par de nombreux SDK.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Avertissements des APIs desktop/JSR non presentes sur Android.
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
