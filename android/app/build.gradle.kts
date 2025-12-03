plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.File

android {
    namespace = "com.example.todo_time_square"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.todo_time_square"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load signing config from android/keystore.properties if present
    signingConfigs {
        create("release") {
            // 从 keystore.properties 加载敏感信息
            val keystoreProperties = rootProject.file("keystore.properties").let {
                Properties().apply { load(it.inputStream()) }
            }

            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            enableV3Signing = true  // 启用 V3 签名（可选）
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            isMinifyEnabled = true  // 开启代码混淆
            isShrinkResources = true // 开启资源压缩
            signingConfig = signingConfigs.getByName("release") // 关联签名配置
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

        }
        debug {
            isDebuggable = true
        }
    }

    // Flavor dimension for Impeller toggle
    flavorDimensions += "impeller"

    productFlavors {
        create("with_impeller") {
            dimension = "impeller"
            manifestPlaceholders["enableImpeller"] = "true"
        }
        create("without_impeller") {
            dimension = "impeller"
            manifestPlaceholders["enableImpeller"] = "false"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add the desugaring library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
