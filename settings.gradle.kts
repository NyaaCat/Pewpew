pluginManagement {
    repositories {
        gradlePluginPortal()
        maven("https://repo.papermc.io/repository/maven-public/")
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "pewpew"

include("paper-api")
include("pewpew-server")

project(":paper-api").projectDir = file("pewpew-api")
