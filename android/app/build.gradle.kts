import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase 설정 파일이 있을 때만 플러그인을 켠다.
// google-services.json 은 커밋 금지(CI 자격증명 검사)라 CI 서버엔 없어서, 무조건 켜면 CI 빌드가 깨진다.
// 로컬·출시 빌드에서는 android/app/google-services.json 을 두면 FCM 이 동작한다.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// 출시용 서명 정보. android/key.properties 에 두며 커밋하지 않는다(.gitignore 처리됨).
// 파일이 없으면(CI·팀원 PC) 디버그 키로 서명해 빌드만 되게 한다.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "kr.ac.knu.cherrishbomb.cherrishbomb_app"
    // Google Play: 2026-08-31 부터 신규 앱·업데이트는 Android 16(API 36) 이상 타겟 필수.
    // Flutter 기본값이 더 높으면 그 값을 쓰고, 낮으면 36 으로 맞춘다.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications(푸시 foreground 표시)가 요구하는 설정
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 출시 후엔 절대 바꿀 수 없는 앱 고유 ID (Play·Firebase 에 이 값으로 등록됨)
        applicationId = "kr.ac.knu.cherrishbomb.cherrishbomb_app"
        minSdk = flutter.minSdkVersion
        targetSdk = maxOf(flutter.targetSdkVersion, 36)
        // 버전은 pubspec.yaml 의 version(예: 1.0.0+2) 을 따른다
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
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
    // isCoreLibraryDesugaringEnabled 와 짝. flutter_local_notifications 18.x 권장 버전
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
