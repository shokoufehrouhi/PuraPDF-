allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// doclens pins CameraX 1.3.4, whose libimage_processing_util_jni.so is only
// 4 KB-aligned; Play requires 16 KB page-size support. 1.4.x ships aligned libs.
allprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.camera") {
                useVersion("1.4.2")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
