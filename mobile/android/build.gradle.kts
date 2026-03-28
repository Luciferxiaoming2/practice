allprojects {
    repositories {
        // 阿里云镜像
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        // 高德 SDK
        maven { url = uri("https://packages.amap.com/repository/maven/") }
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

// 修复旧插件缺少 namespace 的问题
subprojects {
    plugins.withId("com.android.library") {
        val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android.namespace == null || android.namespace!!.isEmpty()) {
            android.namespace = project.group.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
