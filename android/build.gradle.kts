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

// 部分插件(如 media_kit_libs_android_video)自身仍以 compileSdk 31 编译，
// 其打包的 androidx 依赖(AAR metadata)要求消费方 compileSdk >= 34，导致
// checkDebugAarMetadata 失败。此处将编译目标过低的插件子项目统一提升到
// 37(向后兼容，仅影响插件本体的编译期)，属构建配置修正。
// 注意：本 afterEvaluate 块必须注册在下方 evaluationDependsOn(":app") 之前，
// 否则子项目已被提前评估，afterEvaluate 会抛 "already evaluated" 错误。
subprojects {
    afterEvaluate {
        val ext = extensions.findByType(
            com.android.build.api.dsl.LibraryExtension::class.java
        ) ?: return@afterEvaluate
        val current = ext.compileSdk ?: 0
        // record_android 排除：其源码在 compileSdk 37 的平台 stub 下出现 Kotlin
        // 空安全编译错误(MediaCodecInfo.AudioCapabilities 变为 nullable)，且自身
        // 无 AAR metadata 问题，保持原 compileSdk 即可；待升级 record 后可移除排除
        if (current in 1..36 && project.name != "record_android") {
            ext.compileSdk = 37
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
