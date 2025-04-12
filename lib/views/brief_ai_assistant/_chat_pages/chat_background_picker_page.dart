import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/cus_get_storage.dart';
import '../../../common/utils/screen_helper.dart';
import '../_chat_components/_small_tool_widgets.dart';

class ChatBackgroundPickerPage extends StatefulWidget {
  const ChatBackgroundPickerPage({
    super.key,
    required this.chatType,
    required this.title,
  });

  final String chatType;
  final String title;

  @override
  State<ChatBackgroundPickerPage> createState() =>
      _ChatBackgroundPickerPageState();
}

class _ChatBackgroundPickerPageState extends State<ChatBackgroundPickerPage> {
  final MyGetStorage _storage = MyGetStorage();
  String? _selectedBackground;
  double _opacity = 0.2;
  bool _isLoading = true;

  // 保存初始设置，用于取消时恢复
  String? _initialBackground;
  double _initialOpacity = 0.2;

  final List<String> _defaultBackgrounds = [
    'assets/chat_backgrounds/bg1.jpg',
    'assets/chat_backgrounds/bg2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final background =
        widget.chatType == 'branch'
            ? await _storage.getBranchChatBackground()
            : await _storage.getCharacterChatBackground();
    final opacity =
        widget.chatType == 'branch'
            ? await _storage.getBranchChatBackgroundOpacity()
            : await _storage.getCharacterChatBackgroundOpacity();

    setState(() {
      _selectedBackground = background;
      _opacity = opacity ?? 0.2;
      // 保存初始值
      _initialBackground = background;
      _initialOpacity = opacity ?? 0.2;
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
        actions: [
          TextButton(
            onPressed: () {
              // 取消操作，恢复初始设置
              if (widget.chatType == 'branch') {
                _storage.saveBranchChatBackground(_initialBackground);
                _storage.saveBranchChatBackgroundOpacity(_initialOpacity);
              } else {
                _storage.saveCharacterChatBackground(_initialBackground);
                _storage.saveCharacterChatBackgroundOpacity(_initialOpacity);
              }
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 确认操作，保存当前设置
              _saveBackground(_selectedBackground);
              _saveOpacity(_opacity);
              Navigator.pop(context, true);
            },
            child: const Text('确定'),
          ),
        ],
      ),
      // 使用SingleChildScrollView包裹内容，处理可能的溢出问题
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 背景预览区域 - 使用固定高度而非Expanded
            if (_selectedBackground != null)
              Container(
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
                        child: buildCusImage(
                          _selectedBackground!,
                          fit: BoxFit.contain, // 改为contain以避免图片变形
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '透明度: ${(_opacity * 100).toInt()}%',
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '透明度: ${(_opacity * 100).toInt()}%',
                              style: TextStyle(color: Colors.blue),
                            ),
                            Text(
                              '透明度: ${(_opacity * 100).toInt()}%',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 预设背景部分
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '预设背景',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // 改为自适应高度的网格布局，更适合桌面端
            isDesktop
                ? _buildDesktopBackgroundGrid()
                : _buildMobileBackgroundList(),

            // 自定义背景部分 - 修改为更灵活的布局
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

            // 为桌面端添加底部空间，避免内容太靠近底部
            if (isDesktop) SizedBox(height: 32),
          ],
        ),
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

  void _selectBackground(String? background) {
    setState(() {
      _selectedBackground = background;
    });
  }

  Future<void> _pickCustomBackground() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedBackground = pickedFile.path;
      });
    }
  }

  Future<void> _saveBackground(String? path) async {
    if (widget.chatType == 'branch') {
      await _storage.saveBranchChatBackground(path);
    } else {
      await _storage.saveCharacterChatBackground(path);
    }
  }

  Future<void> _saveOpacity(double opacity) async {
    if (widget.chatType == 'branch') {
      await _storage.saveBranchChatBackgroundOpacity(opacity);
    } else {
      await _storage.saveCharacterChatBackgroundOpacity(opacity);
    }
  }
}
