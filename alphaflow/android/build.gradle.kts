plugins {
    // Make sure to use the latest version from the Firebase documentation
    id("com.google.gms.google-services") version "4.3.15" apply false
    // You might also see other plugins here like:
    // id("com.android.application") version "8.X.X" apply false // (use your project's Android Gradle Plugin version)
    // id("org.jetbrains.kotlin.android") version "1.X.X" apply false // (use your project's Kotlin version)
    // Often, for Flutter, these other plugin versions (AGP, Kotlin) are managed in settings.gradle.kts.
    // The critical one for Firebase here is "com.google.gms.google-services".
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
