import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// リリース署名の設定。android/key.properties があればその鍵で署名する(ひな形: key.properties.example)。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

// flutter build の --dart-define / --dart-define-from-file で渡された値。
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it)) }
    ?.mapNotNull { entry ->
        val parts = entry.split("=", limit = 2)
        if (parts.size == 2) parts[0] to parts[1] else null
    }
    ?.toMap()
    ?: emptyMap()

// Google公式のテスト用 AdMob アプリID
val admobTestAppId = "ca-app-pub-3940256099942544~3347511713"

android {
    namespace = "com.piccolong.satto_keisan"
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
        applicationId = "com.piccolong.satto_keisan"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 開発中は常にテスト用の AdMob アプリIDを使う
        manifestPlaceholders["admobAppId"] = admobTestAppId
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties がない間はデバッグ鍵で署名する(`flutter run --release` 用。Google Play には出せない)
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            manifestPlaceholders["admobAppId"] = dartDefines["ADMOB_APP_ID_ANDROID"] ?: admobTestAppId
        }
    }
}

flutter {
    source = "../.."
}

// Google Play 提出用の AAB は、本番の署名と AdMob ID がそろっていなければビルドを止める。
if (gradle.startParameter.taskNames.any { it.contains("bundleRelease", ignoreCase = true) }) {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties がありません。key.properties.example を参考に作成してください。"
        )
    }
    val requiredDefines = listOf("ADMOB_APP_ID_ANDROID", "ADMOB_BANNER_ANDROID", "ADMOB_INTERSTITIAL_ANDROID")
    val missing = requiredDefines.filter { dartDefines[it].isNullOrBlank() || dartDefines[it]!!.contains("XXXX") }
    if (missing.isNotEmpty()) {
        throw GradleException(
            "AdMob の本番IDが未設定です: ${missing.joinToString()}。" +
                "--dart-define-from-file=dart_defines/admob.prod.json を付けてビルドしてください。"
        )
    }
}
