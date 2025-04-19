# 将 flutter 应用构建为 Linux 下 .APPImage 格式

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
