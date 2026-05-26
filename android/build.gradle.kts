group = "com.famedly.fcm_shared_isolate"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
}

val firebaseCoreProject = findProject(":firebase_core")
    ?: throw GradleException("Could not find the firebase_core FlutterFire plugin, have you added it as a dependency in your pubspec?")

if (firebaseCoreProject.properties["FirebaseSDKVersion"] == null) {
    throw GradleException("A newer version of the firebase_core FlutterFire plugin is required, please update your firebase_core pubspec dependency.")
}

fun getRootProjectExtOrCoreProperty(name: String, firebaseCoreProject: Project): Any? {
    if (!rootProject.extra.has("FlutterFire")) {
        return firebaseCoreProject.properties[name]
    }
    val flutterFire = rootProject.extra["FlutterFire"] as? Map<String, Any?>
        ?: return firebaseCoreProject.properties[name]
    return flutterFire[name] ?: firebaseCoreProject.properties[name]
}

android {
    namespace = "com.famedly.fcm_shared_isolate"
    compileSdk = 36

    sourceSets {
        named("main") {
            java.srcDirs("src/main/kotlin")
        }
    }
    defaultConfig {
        minSdk = 23
    }
    lint {
        disable += "InvalidPackage"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    api(firebaseCoreProject)
    api(platform("com.google.firebase:firebase-bom:${getRootProjectExtOrCoreProperty("FirebaseSDKVersion", firebaseCoreProject)}"))
    api("com.google.firebase:firebase-messaging")
}
