plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.zynexbd.livetracking"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.zynexbd.livetracking"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Base URL of the ASP.NET Core API. 10.0.2.2 = host machine when running
        // on the Android emulator; replace with your LAN IP / domain for real devices.
        buildConfigField("String", "API_BASE_URL", "\"http://10.0.2.2:5000/\"")
        buildConfigField("String", "SIGNALR_HUB_URL", "\"http://10.0.2.2:5000/hubs/location\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    buildFeatures {
        viewBinding = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.activity:activity-ktx:1.9.1")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.lifecycle:lifecycle-service:2.8.4")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

    // SignalR client (depends on RxJava for its reactive API)
    implementation("com.microsoft.signalr:signalr:8.0.7")
    implementation("io.reactivex.rxjava3:rxjava:3.1.8")
    implementation("io.reactivex.rxjava3:rxandroid:3.0.2")

    // Location
    implementation("com.google.android.gms:play-services-location:21.3.0")

    // Google Maps
    implementation("com.google.android.gms:play-services-maps:19.0.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
