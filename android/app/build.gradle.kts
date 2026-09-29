import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Configuration de signature release. Le fichier android/key.properties contient les
// mots de passe de la keystore : il n'est JAMAIS versionne (cf. .gitignore).
// Voir android/key.properties.example pour le modele et la commande keytool.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Minification desactivee par defaut : elle n'apporte que quelques Mo sur une app Flutter
// (le code Dart est deja compile AOT et tree-shake) mais peut casser au runtime les plugins
// natifs qui utilisent la reflexion. A activer avec -Pminify=true une fois le parcours
// complet valide (push OneSignal, carte Maps, Crashlytics).
val minifyEnabled = (project.findProperty("minify") as String?)?.toBoolean() ?: false

android {
    namespace = "com.carrementweb.fraya_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.fraya_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // OneSignal Android SDK 5.x requires Android API 23+.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("passenger") {
            dimension = "app"
            applicationId = "fraya.taxi.ci"
            resValue("string", "app_name", "Fraya Taxi")
        }
        create("driver") {
            dimension = "app"
            applicationId = "fraya.taxi.driver.ci"
            resValue("string", "app_name", "Fraya Chauffeur")
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String

                // v2 + v3 sont les schemas qui comptent : ce sont eux qu'Android 7.0+
                // verifie, et minSdk vaut 24 (= Android 7.0). Verifie sur l'APK produit.
                //
                // v1 (JAR signing) reste desactive par AGP malgre le flag ci-dessous, parce
                // qu'il est redondant des que minSdk >= 24 : il ne sert qu'a Android 6 et
                // anterieur, ou l'app ne s'installe de toute facon pas. Le flag est conserve
                // pour qu'il prenne effet automatiquement si minSdk redescendait sous 24.
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            // Sans key.properties (poste sans keystore), on retombe sur la cle de debug
            // pour que `flutter run --release` continue de fonctionner. Un APK signe en
            // debug ne doit JAMAIS etre distribue.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("ATTENTION: android/key.properties introuvable -> APK release signe avec la cle de DEBUG. Ne pas distribuer.")
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = minifyEnabled
            isShrinkResources = minifyEnabled
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
