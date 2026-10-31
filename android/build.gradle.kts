plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.pushplatform.flutter"
version = "1.0.2"

repositories {
    google()
    mavenCentral()
}

// The app also resolves this transitive AAR on its runtime classpath.
rootProject.allprojects {
    repositories {
        maven {
            url = uri("https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/")
            content { includeModule("com.pushplatform", "sdk-android") }
        }
    }
}

extensions.configure<com.android.build.api.dsl.LibraryExtension> {
    namespace = "com.pushplatform.flutter"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("com.pushplatform:sdk-android:1.0.1")

    // Test dependencies
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.3.1")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.0.0")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
}
