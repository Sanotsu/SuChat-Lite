# 将 flutter 应用构建为 Windows 下 exe 应用

编写时为了测试简单，使用脚本时，不仅需要先安装对应工具，还要提前执行 flutter 的打包命令:

```sh
flutter clean
flutter build windows --release
```

## 方法一(推荐): 使用 Enigma Virtual Box

使用[Enigma Virtual Box](https://enigmaprotector.com/en/aboutvb.html)手动打包绿色版 exe 文件。

下载 Enigma Virtual Box 并安装，然后选择 build 的 Windows 应用的文件夹进行封装，就可以构建一个绿色版 exe 文件。

我本来想编写一个 Windows 脚本直接处理，但是没成功，不过手动构建也简单。

## 方法二:使用 7z

使用[7z](https://www.7-zip.org/)

先安装好 7z，再执行 bat 脚本 [build_exe_portable_with_7z](./build_exe_portable_with_7z.bat)。应该就可以把构建好的 Windows 应用封装成一个 exe 的压缩包。最后会放在项目根目录的`dist/7z`文件夹中，解压后运行 `SuChat.exe` 即可正常使用。

## 方法三:使用 Inno Setup

使用[Inno Setup](https://jrsoftware.org/isdl.php)手动打包安装器 exe 文件。

其实和 7z 差不多，也是把构建的 Windows 应用压缩成一个 exe，实际的安装就是解压过程。

也比较简单，而且这个我简单写了个 bat 脚本[build_exe_installer_with_inno](./build_exe_installer_with_inno.bat)。双击允许输入 Inno Setup 完整安装路径即可。最后会放在项目根目录的`dist/inno`文件夹中。
