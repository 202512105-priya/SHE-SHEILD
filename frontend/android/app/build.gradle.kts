plugins {
    id("com.android.application")
    id("kotlin-android")
}

android {
    namespace = "com.example.she_shield"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.she_shield"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
