import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../core/utils/image_color_utils.dart';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../core/storage/cus_get_storage.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../domain/entities/message_font_color.dart';
import '../../domain/entities/character_card.dart';

class ChatBackgroundPickerPage extends StatefulWidget {
  const ChatBackgroundPickerPage({
    super.key,
    required this.title,
    this.currentCharacter,
  });

  final String title;
  // 当前角色(如果对话是角色对话，则传入当前角色)
  final CharacterCard? currentCharacter;

  @override
  State<ChatBackgroundPickerPage> createState() =>
      _ChatBackgroundPickerPageState();
}

class _ChatBackgroundPickerPageState extends State<ChatBackgroundPickerPage>
    with SingleTickerProviderStateMixin {
  final CusGetStorage _storage = CusGetStorage();
  String? _selectedBackground;
  double _opacity = 0.2;
  bool _isLoading = true;

  // 保存初始设置，用于取消时恢复
  String? _initialBackground;
  double _initialOpacity = 0.2;
  MessageFontColor _initialColorConfig = MessageFontColor.defaultConfig();
  MessageFontColor _colorConfig = MessageFontColor.defaultConfig();

  // 选项卡控制器
  late TabController _tabController;

  final List<String> _defaultBackgrounds = [
    'assets/chat_backgrounds/bg1.jpg',
    'assets/chat_backgrounds/bg2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();

    // 如果是角色对话传入了角色，则默认选中字体颜色设置选项卡
    if (widget.currentCharacter != null) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final background = await _storage.getBranchChatBackground();
    final opacity = await _storage.getBranchChatBackgroundOpacity();
    final colorConfig = await _storage.loadMessageFontColor();

    setState(() {
      _selectedBackground = background;
      _opacity = opacity ?? 0.2;
      _colorConfig = colorConfig;

      // 保存初始值
      _initialBackground = background;
      _initialOpacity = opacity ?? 0.2;
      _initialColorConfig = colorConfig;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 获取屏幕尺寸
    final size = MediaQuery.of(context).size;
    final isDesktop = ScreenHelper.isDesktop();

    // 计算预览区域高度 - 添加最小/最大高度限制
    // 最小高度确保在极小窗口也能显示
    // 最大高度避免在大屏幕上过大
    final calculatedHeight = isDesktop ? size.height * 0.33 : size.height * 0.3;
    final previewHeight = calculatedHeight.clamp(
      150.0, // 最小高度
      400.0, // 最大高度
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '背景设置'), Tab(text: '字体颜色')],
        ),
        actions: [
          TextButton(
            // onPressed: () => saveConfig(true),
            // 2025-04-14 取消时直接返回不就好了？
            onPressed: () {
              Navigator.pop(context);
            },

            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => saveAllConfig(false),
            child: const Text('确定'),
          ),
        ],
      ),
      // 使用TabBarView展示不同设置内容
      body: TabBarView(
        controller: _tabController,
        children: [
          // 背景设置选项卡
          _buildBackgroundTab(previewHeight, isDesktop),

          // 字体颜色设置选项卡
          _buildColorTab(previewHeight),
        ],
      ),
    );
  }

  // 背景设置选项卡
  Widget _buildBackgroundTab(double previewHeight, bool isDesktop) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背景预览区域
          if (_selectedBackground != null) _buildPreviewArea(previewHeight),

          // 预设背景部分
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '预设背景',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 根据平台选择不同的布局
          isDesktop
              ? _buildDesktopBackgroundGrid()
              : _buildMobileBackgroundList(),

          // 自定义背景部分
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildCustomBackgroundSection(),
          ),

          // 透明度调整部分
          if (_selectedBackground != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '背景透明度',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _opacity = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('${(_opacity * 100).toInt()}%'),
                ],
              ),
            ),
          ],

          // 为桌面端添加底部空间
          if (isDesktop) SizedBox(height: 32),
        ],
      ),
    );
  }

  // 字体颜色设置选项卡
  Widget _buildColorTab(double previewHeight) {
    var image = widget.currentCharacter?.background ?? _selectedBackground;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 颜色预览区域
          Container(
            width: double.infinity,
            height: previewHeight,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
              image:
                  (image != null && image.trim().isNotEmpty)
                      ? DecorationImage(
                        image: _buildBackgroundImage(image),
                        fit: BoxFit.cover,
                        opacity: _opacity,
                      )
                      : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPreviewText('用户发送消息示例', _colorConfig.userTextColor),
                  SizedBox(height: 12),
                  _buildPreviewText(
                    '模型深度思考示例',
                    _colorConfig.aiThinkingTextColor,
                  ),
                  SizedBox(height: 12),
                  _buildPreviewText('模型正常回复示例', _colorConfig.aiNormalTextColor),
                ],
              ),
            ),
          ),

          // 颜色设置列表
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '消息颜色设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildColorSettingItem(
                  '用户发送消息字体颜色',
                  _colorConfig.userTextColor,
                  () => _selectColor(context, 'user'),
                ),
                _buildColorSettingItem(
                  '模型深度思考字体颜色',
                  _colorConfig.aiThinkingTextColor,
                  () => _selectColor(context, 'aiThinking'),
                ),
                _buildColorSettingItem(
                  '模型正常回复字体颜色',
                  _colorConfig.aiNormalTextColor,
                  () => _selectColor(context, 'aiNormal'),
                ),
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _colorConfig = MessageFontColor.defaultConfig();
                          });
                        },
                        child: const Text('恢复默认颜色设置'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 颜色选择项目
  Widget _buildColorSettingItem(
    String title,
    Color currentColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title, style: TextStyle(color: currentColor)),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: onTap,
    );
  }

  // 预览文本样式
  Widget _buildPreviewText(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 16)),
    );
  }

  // 颜色选择对话框
  Future<void> _selectColor(BuildContext context, String colorType) async {
    Color currentColor;
    switch (colorType) {
      case 'user':
        currentColor = _colorConfig.userTextColor;
        break;
      case 'aiNormal':
        currentColor = _colorConfig.aiNormalTextColor;
        break;
      case 'aiThinking':
        currentColor = _colorConfig.aiThinkingTextColor;
        break;
      default:
        currentColor = Colors.black;
    }

    Color? newColor = await showDialog<Color>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择颜色'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (color) {
                  currentColor = color;
                },
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, currentColor),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (newColor != null) {
      setState(() {
        switch (colorType) {
          case 'user':
            _colorConfig = MessageFontColor(
              userTextColor: newColor,
              aiNormalTextColor: _colorConfig.aiNormalTextColor,
              aiThinkingTextColor: _colorConfig.aiThinkingTextColor,
            );
            break;
          case 'aiNormal':
            _colorConfig = MessageFontColor(
              userTextColor: _colorConfig.userTextColor,
              aiNormalTextColor: newColor,
              aiThinkingTextColor: _colorConfig.aiThinkingTextColor,
            );
            break;
          case 'aiThinking':
            _colorConfig = MessageFontColor(
              userTextColor: _colorConfig.userTextColor,
              aiNormalTextColor: _colorConfig.aiNormalTextColor,
              aiThinkingTextColor: newColor,
            );
            break;
        }
      });
    }
  }

  // 背景预览区域
  Widget _buildPreviewArea(double previewHeight) {
    return Container(
      width: double.infinity,
      height: previewHeight,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: _opacity,
              child: buildNetworkOrFileImage(
                _selectedBackground!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('透明度: ${(_opacity * 100).toInt()}%'),
                  Text(
                    '用户发送消息示例',
                    style: TextStyle(color: _colorConfig.userTextColor),
                  ),
                  Text(
                    '模型深度思考示例',
                    style: TextStyle(color: _colorConfig.aiThinkingTextColor),
                  ),
                  Text(
                    '模型正常回复示例',
                    style: TextStyle(color: _colorConfig.aiNormalTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 自定义背景部分 - 优化以适应窄屏
  Widget _buildCustomBackgroundSection() {
    final isNarrowScreen = MediaQuery.of(context).size.width < 360;

    // 在窄屏上使用垂直布局
    if (isNarrowScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自定义背景',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: _pickCustomBackground,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('选择图片'),
            ),
          ),
        ],
      );
    }

    // 在宽屏上使用水平布局
    return Row(
      children: [
        Expanded(
          child: Text(
            '自定义背景',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _pickCustomBackground,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('选择图片'),
        ),
      ],
    );
  }

  // 移动端使用水平滚动列表
  Widget _buildMobileBackgroundList() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 无背景选项
          _buildNoBackgroundOption(),
          // 默认背景选项
          ..._defaultBackgrounds.map((bg) => _buildBackgroundItem(bg)),
        ],
      ),
    );
  }

  // 桌面端使用网格布局
  Widget _buildDesktopBackgroundGrid() {
    final gridItems = [
      _buildNoBackgroundOption(isGridItem: true),
      ..._defaultBackgrounds.map(
        (bg) => _buildBackgroundItem(bg, isGridItem: true),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(spacing: 16, runSpacing: 16, children: gridItems),
    );
  }

  // 无背景选项
  Widget _buildNoBackgroundOption({bool isGridItem = false}) {
    final width = isGridItem ? 120.0 : 67.0;
    final height = isGridItem ? 120.0 : 120.0;

    return GestureDetector(
      onTap: () => _selectBackground(null),
      child: Container(
        width: width,
        height: height,
        margin: isGridItem ? EdgeInsets.zero : EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _selectedBackground == null
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text('无背景', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBackgroundItem(String background, {bool isGridItem = false}) {
    final isSelected = _selectedBackground == background;
    final width = isGridItem ? 120.0 : 67.0;
    final height = isGridItem ? 120.0 : 120.0;

    return GestureDetector(
      onTap: () => _selectBackground(background),
      child: Container(
        width: width,
        height: height,
        margin: isGridItem ? EdgeInsets.zero : EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
            width: 2,
          ),
          image: DecorationImage(
            image: AssetImage(background),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  ImageProvider _buildBackgroundImage(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  void _selectBackground(String? background) {
    setState(() {
      _selectedBackground = background;
    });
  }

  Future<void> _pickCustomBackground() async {
    final pickedFile = await ImagePickerUtils.pickSingleImage();

    if (pickedFile != null) {
      setState(() {
        _selectedBackground = pickedFile.path;
      });
    }
  }

  // 选择图片后保存、取消时恢复初始化都会用到这个
  Future<void> saveAllConfig(bool isCancel) async {
    // 显示加载提示
    final closeToast = ToastUtils.showLoading('对话背景保存中...');

    // 确保UI有机会先绘制加载动画
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      // 1 保存背景图
      var path = isCancel ? _initialBackground : _selectedBackground;
      await _storage.saveBranchChatBackground(path);

      // 保存背景图主色调，用于构建侧边栏背景色
      if (path != null) {
        try {
          // 使用ImageColorHelper在隔离线程中提取颜色
          // 这样不会阻塞主线程，UI可以保持响应
          Color dominantColor = await ImageColorUtils.extractDominantColor(
            path,
          );

          await CusGetStorage().saveBranchChatHistoryPanelBgColor(
            dominantColor.toARGB32(),
          );
        } catch (e) {
          // 使用默认颜色
          await CusGetStorage().saveBranchChatHistoryPanelBgColor(
            Colors.blueGrey.shade100.toARGB32(),
          );
        }
      } else {
        // 如果背景图为空(无背景)，则使用默认颜色
        await CusGetStorage().saveBranchChatHistoryPanelBgColor(
          Colors.blueGrey.shade100.toARGB32(),
        );
      }

      // 2 保存背景色透明度
      await _storage.saveBranchChatBackgroundOpacity(
        isCancel ? _initialOpacity : _opacity,
      );

      // 3 保存字体颜色配置
      await _storage.saveMessageFontColor(
        isCancel ? _initialColorConfig : _colorConfig,
      );

      if (!mounted) return;
      Navigator.pop(context, isCancel ? false : true);
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, "保存设置时出错", e.toString());
      }
    } finally {
      // 确保关闭加载提示
      closeToast();
    }
  }
}
