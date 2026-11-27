
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.*

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.atomicfu)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.parcelize)
    alias(libs.plugins.bugsnag)
}

val jdkVersion = project.findProperty("jdk.version").toString()

val compileSdkVersion = project.findProperty("compileSdk").toString().toInt()
val compileSdkMinorVersion = project.findProperty("compileSdkMinor").toString().toInt()
val targetSdkVersion = project.findProperty("targetSdk").toString().toInt()
val minSdkVersion = project.findProperty("minSdk").toString().toInt()
val waLab = providers.gradleProperty("waLab").orNull == "true"

val labLicenses by tasks.registering(Copy::class) {
    from(rootProject.file("LICENSE"), rootProject.file("LICENSE.md"))
    into(layout.buildDirectory.dir("generated/labLicenses"))
}

android {
    compileSdk {
        version = release(compileSdkVersion) {
            minorApiLevel = compileSdkMinorVersion
        }
    }

    defaultConfig {
        buildConfigField("boolean", "WA_LAB", waLab.toString())
        val sourceSha = providers.gradleProperty("applicationSha").orNull ?: "UNKNOWN"
        require(sourceSha == "UNKNOWN" || sourceSha.matches(Regex("[0-9a-f]{40}")))
        buildConfigField("String", "LAB_SOURCE_SHA", "\"$sourceSha\"")
        manifestPlaceholders["labSourceSha"] = sourceSha
        namespace = "tk.zwander.lockscreenwidgets"
        applicationId = if (waLab) "com.example.keyboardtest.walab" else "tk.zwander.lockscreenwidgets"
        minSdk = minSdkVersion
        targetSdk = targetSdkVersion
        versionCode = 222
        versionName = "4.7.5"

        manifestPlaceholders["build_uuid"] = UUID.nameUUIDFromBytes("LockscreenWidgets_${versionCode}".toByteArray()).toString()
        manifestPlaceholders["isDebug"] = false
        manifestPlaceholders["wallpaperPermission"] = if (waLab) "com.example.keyboardtest.walab.WALLPAPER_INTERCONNECT" else "tk.zwander.lockscreenwidgets.WALLPAPER_INTERCONNECT"

        @Suppress("UnstableApiUsage")
        externalNativeBuild {
            cmake {
                cppFlags += ""
                arguments.add("-DANDROID_WEAK_API_DEFS=ON")
            }

            ndkBuild {
                arguments.add("LOCAL_LDFLAGS+=-Wl,--build-id=none")
            }
        }

        buildTypes {
            debug {
                manifestPlaceholders["isDebug"] = true
            }
        }
    }

    buildFeatures {
        viewBinding = true
        compose = true
        buildConfig = true
        aidl = true
        prefab = true
    }

    buildTypes {
        if (waLab) {
            create("profile") {
                initWith(getByName("debug"))
                matchingFallbacks += listOf("debug", "release")
                signingConfig = signingConfigs.getByName("debug")
                manifestPlaceholders["isDebug"] = false
            }
        }
        all {
            buildConfigField("Integer", "DATABASE_VERSION", project.findProperty("databaseVersion").toString())
        }
    }

    if (waLab) sourceSets.getByName("profile").assets.srcDir(labLicenses)

    compileOptions {
        sourceCompatibility = JavaVersion.toVersion(jdkVersion)
        targetCompatibility = JavaVersion.toVersion(jdkVersion)
    }

    packaging {
        resources.excludes.add("META-INF/library_release.kotlin_module")
        jniLibs.pickFirsts += "**/libbugsnag-ndk.so"
    }

    externalNativeBuild {
        cmake {
            path = file("CMakeLists.txt")
            version = "3.22.1"
        }
    }

    ndkVersion = "29.0.14206865"

    dependenciesInfo {
        // Disables dependency metadata when building APKs (for IzzyOnDroid/F-Droid)
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles (for Google Play)
        includeInBundle = false
    }
}

afterEvaluate {
    base {
        archivesName.set("WidgetsAnywhere_${android.defaultConfig.versionName}")
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.fromTarget(jdkVersion))
        freeCompilerArgs.addAll(
            "-Xcollection-literals",
            "-Xname-based-destructuring=complete",
        )
    }
}

bugsnag {
    ndkRoot = project.androidComponents.sdkComponents.ndkDirectory.get().asFile
    buildUuid = project.android.defaultConfig.manifestPlaceholders["build_uuid"].toString()
}

dependencies {
    if (waLab) {
        add("profileImplementation", "com.example.keyboardtest_module:flutter_profile:1.0")
    }
    implementation(fileTree("libs") { include("*.jar") })
    implementation(libs.kotlin.stdlib)
    implementation(libs.kotlin.reflect)
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.atomicfu)

    implementation(libs.core.ktx)
    implementation(libs.core.remoteviews)
    implementation(libs.appcompat)
    implementation(libs.constraintlayout)
    implementation(libs.recyclerview)
    implementation(libs.preference.ktx)

    implementation(libs.hiddenapibypass)
    implementation(libs.gson)
    implementation(libs.material)
    implementation(libs.byte.buddy.android)
    implementation(libs.patreonSupportersRetrieval)
    implementation(libs.composeIntroSlider)

    implementation(platform(libs.compose.bom.alpha))
    implementation(libs.activity.compose)
    implementation(libs.compose.animation)
    implementation(libs.compose.foundation)
    implementation(libs.compose.foundation.layout)
    implementation(libs.compose.ui.tooling)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons.core)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.lifecycle.runtime.ktx)
    implementation(libs.lifecycle.service)

    implementation(libs.accompanist.drawablepainter)

    implementation(libs.bugsnag.android)
    implementation(libs.bugsnag.exitinfo)
    implementation(libs.bugsnag.android.performance)
    implementation(libs.bugsnag.android.performance.appcompat)
    implementation(libs.bugsnag.android.performance.compose)

    implementation(libs.taskerpluginlibrary)

    implementation(libs.relinker)
    implementation(libs.msz.progress.indicator)

    implementation(libs.shizuku.api)
    implementation(libs.shizuku.provider)

    implementation(libs.storage)

    implementation(libs.colorpicker.compose)
    implementation(libs.reorderable)
    implementation(libs.miui.autostart)

    implementation(libs.pagerindicator)

    implementation(libs.lazyspannedgrid)
    implementation(libs.lazyspannedgrid.reorderable)
    implementation(libs.lazyspannedgrid.reorderable.calvin)

    implementation(libs.glance)
    implementation(libs.glance.appwidget)

    implementation(project(":lswinterconnect"))

    coreLibraryDesugaring(libs.desugar.jdk.libs)
}
