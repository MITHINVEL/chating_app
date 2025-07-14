
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = file("../../build")

rootProject.setBuildDir(newBuildDir)

subprojects {
    setBuildDir(file("../../build/${project.name}"))
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
