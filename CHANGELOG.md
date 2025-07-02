# Changelog

一些较大变更、新功能、bug 修复等记录放在此处，仅做参看的提交更新.

## 0.1.2-beta.1

- chore:
  - 更新开发环境到 flutter 3.32.4，以及更新相关依赖到最新
- feat:
  - 添加了简单的个人信息管理
  - 添加了简单的“训练助手”功能模块
  - 添加了简单的“饮食日记”功能模块
  - 添加了简单的“极简记账”功能模块
- refactor:
  - 重构了更多功能入口和更多功能页面
  - 移动端对话历史记录从抽屉改为单独页面
- fix:
  - 移除了本地解析 doc 文件内容的功能(相关依赖库太老旧影响主流库版本更新)
  - 修正了一些错误和调整了一些细节

## 0.1.1-beta.1

- feat:
  - 添加更多功能：
    - 图片生成、视频生成、语音合成、录音文件识别
- refactor:
  - 重构了项目架构，更简化类似功能模块结构
  - 重构拆分了分支对话主页面大文件
  - 重构了分支对话的输入组件，分为上方输入下方功能按钮
  - 统一使用 audio_waveforms 来进行简单的移动平台的音频录制和本地播放
  - Android 原生代码简单实现 m4a 录音转为 pcm 格式，不再使用 ffmpeg_kit_flutter，减小 apk 体积
  - 重新规划了应用文件存放位置，**若要使用旧版数据，请手动移动数据库相关文件**，后续不会再改变文件夹结构了

具体文件和文件夹迁移：

- 打开文件管理器，进入 “SuChatFiles/”路径，桌面端在“文档/SuChatFiles/”中
- 新建加黑的层级文件夹并移动旧文件:
  - SuChatFiles/embedded_suchat.db -> SuChatFiles/**DB/sqlite_db**/embedded_suchat.db
  - SuChatFiles/embedded_suchat.db-journal -> SuChatFiles/**DB/sqlite_db**/embedded_suchat.db-journal
  - SuChatFiles/objectbox/ -> SuChatFiles/**DB**/objectbox/
- 启动应用(需确保杀掉进程后重新加载)

注意 1：

- 因为使用讯飞语音识别时，要把录音 m4a 转为 pcm 格式，因而使用了 [ffmpeg_kit_flutter](https://github.com/arthenica/ffmpeg-kit) 库
- 但这个库因为[一些原因](https://tanersener.medium.com/saying-goodbye-to-ffmpegkit-33ae939767e1)结束维护了，所以先改使用 [ffmpeg_kit_flutter_new](https://github.com/sk3llo/ffmpeg_kit_flutter)
- 但是，仅这一项改动，apk 的体积增加了很多
- 所以在 Android 端，实现原生简单的 acc 编码的 m4a 录音转 pcm 格式，参看 [AudioConverterPlugin.kt](android/app/src/main/kotlin/com/swm/suchat_lite/AudioConverterPlugin.kt)

```sh
# 0.1.0 旧版本使用的临时替代库
# ffmpeg_kit_flutter:
#   git:
#     url: https://github.com/MSOB7YY/ffmpeg-kit
#     path: flutter/flutter
#     ref: 1d29b16
Running Gradle task 'assembleRelease'...                          601.7s
✓ Built build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (31.8MB)
✓ Built build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (31.9MB)
✓ Built build/app/outputs/flutter-apk/app-x86_64-release.apk (33.9MB)

# 0.1.1 使用ffmpeg_kit_flutter_new: ^1.6.1
Running Gradle task 'assembleRelease'...                          584.6s
✓ Built build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (51.1MB)
✓ Built build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (36.9MB)
✓ Built build/app/outputs/flutter-apk/app-x86_64-release.apk (39.7MB)

# 简单原生实现 m4a 转 pcm，不使用任何ffmpeg_kit_flutter库
Running Gradle task 'assembleRelease'...                          527.6s
✓ Built build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (22.4MB)
✓ Built build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (22.8MB)
✓ Built build/app/outputs/flutter-apk/app-x86_64-release.apk (23.8MB)
```

注意 2：

- 桌面端不再支持录音和音频播放(单纯图省事，audio_waveforms 不支持桌面端)
- 目前移动端可以录音的地方:
  - 对话主页的语音转文本输入
  - 声音复刻的语音录制
  - 语音识别的语音录制

## 0.1.0-beta.1

首次打包版本，基本完成了 AI 聊天预想的所有功能。

- feat:
  - 调用在线云平台大模型 API 进行对话
    - 分支对话、角色扮演、各种简单的自定义、模型和 AK 管理、简单的备份恢复等。
