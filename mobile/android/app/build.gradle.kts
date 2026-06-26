import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val isReleaseBuild = gradle.startParameter.taskNames.any { 
    it.contains("bundleRelease", ignoreCase = true) ||
    it.contains("assembleRelease", ignoreCase = true) ||
    it.contains("packageRelease", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { fis ->
        keystoreProperties.load(fis)
    }
}

if (isReleaseBuild) {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException("Missing key.properties. Release build requires upload signing config. Please create mobile/android/key.properties using mobile/android/key.properties.example")
    }
    val keyAlias = keystoreProperties["keyAlias"] as String?
    val keyPassword = keystoreProperties["keyPassword"] as String?
    val storeFileName = keystoreProperties["storeFile"] as String?
    val storePassword = keystoreProperties["storePassword"] as String?

    if (keyAlias.isNullOrBlank() || keyPassword.isNullOrBlank() || storeFileName.isNullOrBlank() || storePassword.isNullOrBlank()) {
        throw GradleException("key.properties is incomplete. All fields (keyAlias, keyPassword, storeFile, storePassword) must be specified for a release build.")
    }

    val storeFileObj = rootProject.file(storeFileName)
    if (!storeFileObj.exists()) {
        throw GradleException("Keystore file defined in key.properties does not exist at: ${storeFileObj.absolutePath}")
    }
}

android {
    namespace = "com.esquilospeak.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.esquilospeak.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                val storeFileName = keystoreProperties["storeFile"] as String?
                storeFile = storeFileName?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
