group = "abdurrahmankaraoglu.app.advanced_background_locator"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "abdurrahmankaraoglu.app.advanced_background_locator"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }

    lint {
        abortOnError = false
    }
}

// Built-in Kotlin (AGP 9+): the plugin does not apply the Kotlin Gradle plugin itself.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("com.google.android.gms:play-services-location:21.4.0")
    implementation("com.google.code.gson:gson:2.14.0")
}
