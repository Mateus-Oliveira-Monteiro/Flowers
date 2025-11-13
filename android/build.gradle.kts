allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Move all build outputs to the project root's build/ directory
// From android/ directory, the correct relative path is ../build
val rootBuildDirProvider = rootProject.layout.buildDirectory.dir("../build")
rootProject.layout.buildDirectory.set(rootBuildDirProvider)

subprojects {
    // Each subproject writes under build/<moduleName>
    val subprojectBuildDirProvider = rootBuildDirProvider.map { it.dir(project.name) }
    layout.buildDirectory.set(subprojectBuildDirProvider)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
