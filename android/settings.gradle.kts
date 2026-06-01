pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("com.android.library") version "8.3.0" apply false
        id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    }
}

rootProject.name = "fcm_shared_isolate"
