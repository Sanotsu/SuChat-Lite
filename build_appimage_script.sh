#!/bin/bash
# 构建 Flutter 应用
flutter clean
flutter build linux --release -v

# 复制图标到临时位置
cp assets/brand.png build/linux/x64/release/

# 准备 AppDir
cd build/linux/x64/release/
mkdir -p AppDir
cp -r bundle/* AppDir/

# 复制图标到 AppDir 后删除
cp brand.png AppDir/
rm brand.png

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

# 创建桌面文件
cat > AppDir/SuChat.desktop << 'EOF'
[Desktop Entry]
Name=SuChat
Exec=AppRun
Icon=brand
Type=Application
Categories=Utility;
EOF

# 生成 AppImage
# appimagetool AppDir
appimagetool AppDir -u 'Icon=brand.png'
