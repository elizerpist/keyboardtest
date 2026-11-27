@file:Suppress("UnstableApiUsage")

include(":lswinterconnect")


include(":lswwallpaper")


pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        mavenLocal()
        if (providers.gradleProperty("waLab").orNull == "true") {
            maven { url = uri("../../integrations/keyboardtest_module/build/host/outputs/repo") }
            maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        }
        maven("https://jitpack.io")
    }
}

include(":app")
rootProject.name = "Lockscreen Widgets"
