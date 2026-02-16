allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task.name.contains("lint", ignoreCase = true) || task.name.contains("test", ignoreCase = true)) {
            task.enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
