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
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task.name.contains("lint", ignoreCase = true) || task.name.contains("test", ignoreCase = true)) {
            task.enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
