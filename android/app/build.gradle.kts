import java.util.Properties

// **リリース署名の鍵。** `android/key.properties` はリポジトリに入れない
// （`.gitignore` 済み。実体は Google Drive と同期する。`docs/secrets.md` 参照。
// gyumesy-frontend-app と同じ作り）。
//
// **無い時は debug 鍵のままにする。** ここで落とすと、鍵を持っていない人が
// デバッグビルドすらできなくなる。**debug 鍵のまま配らないよう、配信の lane
// （`android/fastlane/Fastfile` の `ensure_release_signing`）が見張っている。**
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // `google-services.json`（Firebase プロジェクト `tonsoku` の公開値）を読む
    id("com.google.gms.google-services")
}

android {
    namespace = "com.gyumesy.tonsoku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications が要求する。**入れないとビルドが通らない**
        // （通知の日時指定に java.time を使っていて、古い端末向けに変換が要る。
        // gyumesy と同じ）
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gyumesy.tonsoku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // **鍵が無ければ debug のまま。** 鍵を持っていない人でも
            // `flutter run --release` が通るようにする（配信は鍵を持つ人だけ）
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // **`shrinkResources` を入れる時は通知アイコンを守ること**（gyumesy の注記）。
            // R8 の資源収縮は `ic_stat_notification` を「参照されていない」と
            // 判断して落とす（参照しているのは AndroidManifest の meta-data と
            // Dart の文字列で、コードからの参照が無い）。**落ちても例外は出ず、
            // 通知が黙って出なくなるだけ**なので気づけない。
            // `res/raw/keep.xml` に
            // `tools:keep="@drawable/ic_stat_notification"` を書き、
            // 入れた後に実機で 1 度受け取って確かめること。
            // 参考: flutter_local_notifications の README
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
