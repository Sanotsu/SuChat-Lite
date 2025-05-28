# 将 flutter 应用构建为 Linux 下 .APPImage 格式

## 方法一(推荐)

使用[AppImage/appimagetool](https://github.com/AppImage/appimagetool)打包

1. 从[releases](https://github.com/AppImage/appimagetool/releases)中下载最新版本，应用名类似`appimagetool-x86_64.AppImage`
2. 在下载的应用目录执行下面命令

```sh
chmod +x appimagetool-x86_64.AppImage
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
```

3. 执行项目根目录的 AppImage 打包脚本

```sh
chmod +x build_appimage_script.sh
./build_appimage_script.sh
```

成功执行之后，打包后的 AppImage 应用应该在项目根目录下`dist/appimage/`中，类似：

```sh
dist/appimage/SuChat-x86_64.AppImage
```

## 方法二(旧版本做法)

我是使用[AppImageCrafters/appimage-builder](https://github.com/AppImageCrafters/appimage-builder)来实现的，Flutter 打包部分可参看其官方文档[Flutter Application](https://appimage-builder.readthedocs.io/en/latest/examples/flutter.html)部分。

### 1 安装 appimage-builder

我是直接去其 github 中下载最新的 [release](https://github.com/AppImageCrafters/appimage-builder/releases)。

或者官方使用命令下载：

```sh
wget -O appimage-builder-x86_64.AppImage https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage
chmod +x appimage-builder-x86_64.AppImage
```

### 2 flutter 构建 Linux 应用

先使用 flutter 命令打包 flutter 应用成 Linux 的 bundle:

```sh
#flutter项目中执行
flutter build linux --release
```

成功构建 Linux 应用后，位置应该在项目相对路径的 build 下:

```sh
build/linux/x64/release/bundle/SuChat
```

### 3 创建 AppDir 结构

我是按照示例，先创建了一个打包工作目录`for-build-appimage`，把下载下来的`appimage-builder-1.1.0-x86_64.AppImage`放进去。然后在里面按照官网创建了`AppDir`文件夹。接着在 AppDir 中创建标准的 AppDir 目录结构。

#### 3.1 复制 Flutter 应用文件

将 Flutter 构建的 bundle 目录内容复制到 `AppDir/usr/bin`.

#### 3.2 创建 `.desktop` 文件

在 `AppDir/usr/share/applications/` 下创建 `suchat.desktop`:

```sh
[Desktop Entry]
Name=SuChat
Exec=/usr/bin/bundle/SuChat
Icon=suchat
Type=Application
Categories=Utility;
```

注意：Icon 需要对应 `AppDir/usr/share/icons/`，而且只需要图标名，不要路径和图片后缀。

此时的`for-build-appimage`文件夹内部结构如下：

```sh
.
├── AppDir
│   └── usr
│       ├── bin
│       │   └── bundle # flutter打包后的文件夹
│       ├── lib
│       └── share
│           ├── applications
│           │   └── suchat.desktop
│           └── icons
│               └── suchat.png
└── appimage-builder-1.1.0-x86_64.AppImage
```

### 4 使用 appimage-builder 打包

如果是手动下载的，可能需要授权:

```sh
# 给应用授权
chmod +x ./appimage-builder-1.1.0-x86_64.AppImage
```

然后生成 `AppImageBuilder.yml` 配置文件。进入`for-build-appimage`后，执行下面命令：

```sh
./appimage-builder-1.1.0-x86_64.AppImage --generate

# 此时我选填的配置如下:
INFO:Generator:Searching AppDir
? ID [Eg: com.example.app]: com.swm.suchat
? Application Name: SuChat
? Icon: suchat
? Executable path: usr/bin/bundle/SuChat
? Arguments [Default: $@]: $@
? Version [Eg: 1.0.0]: 0.0.1-beta.1
? Update Information [Default: guess]: guess
? Architecture: x86_64
```

如果成功，在`for-build-appimage`中会创建好`AppImageBuilder.yml`，其中代码类似:

```yml
# appimage-builder recipe see https://appimage-builder.readthedocs.io for details
version: 1
AppDir:
  path: /home/david/SOFT/for-build-appimage/AppDir
  app_info:
    id: com.swm.suchat
    name: SuChat
    icon: suchat
    version: 0.0.1-beta.1
    exec: usr/bin/bundle/SuChat
    exec_args: $@
  apt:
    xxx……
  test:
    fedora-30:
      image: appimagecrafters/tests-env:fedora-30
      command: ./AppRun
    xxx……
AppImage:
  arch: x86_64
  update-information: guess
```

最后执行打包命令:

```sh
./appimage-builder-1.1.0-x86_64.AppImage --recipe AppImageBuilder.yml
```

可能国内 docker 镜像无法正常范围的话，在运行测试时会有拉取不了镜像等报错。所以如果不需要测试，可以跳过。
将`AppImageBuilder.yml`中`test`部分改为如下：

```yml
test:
  skip: true
```

或者直接在打包时跳过:

```sh
./appimage-builder-1.1.0-x86_64.AppImage --recipe AppImageBuilder.yml --skip-test
```

成功打包之后，此时的工作目录大概如下:

```sh
.
├── AppDir
│   ├── AppRun
│   ├── AppRun.env
│   ├── com.swm.suchat.desktop
│   ├── etc
│   ├── lib
│   ├── lib64
│   ├── runtime
│   ├── suchat.png
│   └── usr
│       ├── bin
│       │   └── bundle
│       ├── lib
│       └── share
│           ├── applications
│           │   └── suchat.desktop
│           ├── doc
│           ├── icons
│           │   └── suchat.png
│           └── lintian
├── appimage-build
├── appimage-builder-1.1.0-x86_64.AppImage
├── AppImageBuilder.yml
├── SuChat-0.0.1-beta.1-x86_64.AppImage
└── SuChat-0.0.1-beta.1-x86_64.AppImage.zsync
```

而`SuChat-0.0.1-beta.1-x86_64.AppImage`就是我们最后打包的应用了。因为配置时设置的 guess 权限，所以双击就可以运行。如果不行，给予权限后双击即可:

```sh
chmod +x SuChat-0.0.1-beta.1-x86_64.AppImage
```

## 打包的应用无法切换输入法的问题

Linux 下(开发机 Ubuntu22.04) 项目 debug 时，在 app 输入框输入内容，输入法可正常切换；但是 build release 之后，按键盘就输入对应英文，没法唤起输入法并切换。

暂时不知道为什么，临时的解决方法如下:

1. 在开发机安装 ibus-1.0 和 fcitx 的开发文件

```sh
sudo apt update
# IBus
sudo apt install libibus-1.0-dev
# Fcitx
sudo apt install fcitx-libs-dev fcitx-frontend-gtk3

# 验证是否安装成功：
pkg-config --modversion ibus-1.0  # 应输出版本号（如 1.5.26）

# 检查开发文件是否存在
ls /usr/include/fcitx-*/          # 头文件
ls /usr/lib/x86_64-linux-gnu/pkgconfig/fcitx*.pc  # pkg-config 文件
```

2. 在项目的 linux 构建文件中加入相关配置

在`linux/flutter/CMakeLists.txt`中，#在文件末尾（或 target_link_libraries 部分后）添加以下内容：

```cmake
# === 输入法支持（优先 Fcitx，次选 IBus）===
message(STATUS "正在配置输入法支持...")

# 1. 优先查找 Fcitx（针对中文输入优化）
pkg_check_modules(FCITX QUIET IMPORTED_TARGET
    fcitx-gtk              # 核心库
    fcitx-frontend-gtk3    # GTK3 前端
)
if(FCITX_FOUND)
    target_link_libraries(flutter INTERFACE PkgConfig::FCITX)
    message(STATUS "已启用 Fcitx 输入法支持（中文优化）")
else()
    # 2. 次选 IBus（通用后备方案）
    pkg_check_modules(IBUS QUIET IMPORTED_TARGET ibus-1.0)
    if(IBUS_FOUND)
        target_link_libraries(flutter INTERFACE PkgConfig::IBUS)
        message(STATUS "已启用 IBus 输入法支持（基础支持）")
    else()
        # 3. 两者均未找到
        message(WARNING "未找到 Fcitx 或 IBus 开发库，Release 版中文输入可能受限")
        message(WARNING "解决方案：安装 fcitx-libs-dev 或 libibus-1.0-dev")
        message(WARNING "  Fcitx用户: sudo apt install fcitx-libs-dev fcitx-frontend-gtk3 fcitx-config-gtk")
        message(WARNING "  IBus用户: sudo apt install libibus-1.0-dev")
    endif()
endif()
```

这样在执行`flutter build linux --release -v`命令时应该能看到输入法配置的消息。

在 build 完成之后，在项目根目录终端检查最终链接库，执行

```sh
ldd build/linux/x64/release/bundle/your_app | grep -E "fcitx|ibus"
```

会输出类似内容:

```sh
libibus-1.0.so.5 => /lib/x86_64-linux-gnu/libibus-1.0.so.5 (0x00007f9911041000)
```

同时，在构建 AppImage 的脚本`build_appimage_script.sh`也有相关的配置，就是配置 AppRun:

```sh
# 创建 AppRun
cat > AppDir/AppRun << 'EOF'
#!/bin/bash
# 设置输入法和库路径(不添加可能打包后的应用切不了中文输入法)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"
# 启动应用
exec "${APPDIR}/SuChat" "$@"
EOF
chmod +x AppDir/AppRun
```

**我的个例，一套流程下来，虽然开发依赖有装 fcitx，但始终检测不到，使用的 ibus。**
但之后打包成 AppImage 格式后输入法可以切换到我安装的输入法，正常输入中文了。
