import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Load keystore properties for release signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dilivvafast.app"
    // Hardcoded to 36: Google Play requires targetSdk >= 36 for new submissions
    // by August 31, 2026 (existing apps by Nov 1, 2026).
    // Using flutter.compileSdkVersion would inherit SDK 35 from Flutter 3.24 defaults.
    compileSdk = 36
    ndkVersion = "27.1.12297006"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dilivvafast.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36  // Required: Google Play mandates API 36 for new submissions by Aug 31 2026
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Multidex support for large apps
        multiDexEnabled = true
    }

    // Two builds of the same app, pointed at two Firebase projects.
    //
    //   production -> fast-delivery-d8d5c   (android/app/google-services.json)
    //   staging    -> dilivvafast-staging   (android/app/src/staging/google-services.json)
    //
    // Staging has its own package name, so it installs alongside the real app
    // on the same phone instead of replacing it, and shows up as
    // "Dilivvafast Staging" in the launcher. The Dart side picks its Firebase
    // options from the same flavor via appFlavor — see lib/core/config/
    // app_environment.dart.
    //
    //   flutter run   --flavor staging
    //   flutter build apk --release --flavor production
    flavorDimensions += "env"
    productFlavors {
        create("production") {
            dimension = "env"
            resValue("string", "app_name", "Dilivvafast")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Dilivvafast Staging")
        }
    }

    // Release signing configuration
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falling back to the debug key keeps `flutter build apk --release`
            // working on a machine without the keystore, which is genuinely
            // useful for local smoke testing. It is dangerous silently: a
            // debug-signed artefact looks like a release build, and Play
            // rejects it only at upload time.
            //
            // So: warn loudly always, and refuse outright when the caller says
            // this build is meant to be shippable. CI passes
            // -PrequireReleaseSigning=true for the appbundle job.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                val requireRealSigning =
                    (project.findProperty("requireReleaseSigning") as String?)
                        ?.toBoolean() ?: false
                if (requireRealSigning) {
                    throw GradleException(
                        "android/key.properties is missing, so this release " +
                            "build would be signed with the DEBUG key. " +
                            "Provide the keystore, or drop " +
                            "-PrequireReleaseSigning=true if you only want a " +
                            "local test build."
                    )
                }
                logger.warn(
                    "\n**********************************************************\n" +
                        "WARNING: android/key.properties not found.\n" +
                        "This release build is signed with the DEBUG key and is\n" +
                        "NOT publishable. Google Play will reject it.\n" +
                        "**********************************************************\n"
                )
                signingConfigs.getByName("debug")
            }

            // Enable R8 code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Enable Crashlytics mapping file upload for deobfuscation
            // Requires com.google.firebase.crashlytics plugin
            ndk {
                debugSymbolLevel = "FULL"
            }
        }

        debug {
            // Disable Crashlytics in debug to speed up builds
            extra["enableCrashlytics"] = false
        }
    }

    // Enable build config generation
    buildFeatures {
        buildConfig = true
    }

    // Lint options
    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
