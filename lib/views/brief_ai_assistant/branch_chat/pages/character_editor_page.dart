import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/utils/image_picker_helper.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_store.dart';
import '../../../../models/brief_ai_tools/branch_chat/character_card.dart';
import '../../../../models/brief_ai_tools/branch_chat/character_store.dart';
import '../../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../../services/cus_get_storage.dart';
import '../../../../services/model_manager_service.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../_chat_components/_small_tool_widgets.dart';
import '../components/adaptive_model_selector.dart';
import '../components/message_color_config.dart';

class CharacterEditorPage extends StatefulWidget {
  final CharacterCard? character;

  const CharacterEditorPage({super.key, this.character});

  @override
  State<CharacterEditorPage> createState() => _CharacterEditorPageState();
}

class _CharacterEditorPageState extends State<CharacterEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personalityController = TextEditingController();
  final _scenarioController = TextEditingController();
  final _firstMessageController = TextEditingController();
  final _exampleDialogueController = TextEditingController();
  final _tagsController = TextEditingController();

  String _avatarPath = '';
  String? _backgroundPath;
  double _backgroundOpacity = 0.2;
  CusBriefLLMSpec? _preferredModel;
  bool _isEditing = false;
  bool isSaving = false;

  // 当前字体颜色(这里设默认，初始化时更新)
  MessageColorConfig _colorConfig = MessageColorConfig.defaultConfig();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.character != null;

    if (_isEditing) {
      _nameController.text = widget.character!.name;
      _descriptionController.text = widget.character!.description;
      _personalityController.text = widget.character!.personality;
      _scenarioController.text = widget.character!.scenario;
      _firstMessageController.text = widget.character!.firstMessage;
      _exampleDialogueController.text = widget.character!.exampleDialogue;
      _tagsController.text = widget.character!.tags.join(', ');
      _avatarPath = widget.character!.avatar;
      _backgroundPath = widget.character!.background;
      _backgroundOpacity = widget.character!.backgroundOpacity ?? 0.2;
      _preferredModel = widget.character!.preferredModel;
    }

    _loadColorConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _scenarioController.dispose();
    _firstMessageController.dispose();
    _exampleDialogueController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadColorConfig() async {
    final config = await MyGetStorage().loadMessageColorConfig();

    setState(() {
      _colorConfig = config;
    });
  }

  Future<void> _selectModel() async {
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
    ]);

    if (!mounted) return;

    // 使用自适应模型选择器
    final result = await AdaptiveModelSelector.show(
      context: context,
      models: availableModels,
      selectedModel: _preferredModel,
      title: '选择角色偏好模型',
    );

    if (result != null) {
      setState(() {
        _preferredModel = result;
      });
    }
  }

  Future<void> _saveCharacter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final store = await CharacterStore.create();

      // 解析标签
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      if (_isEditing) {
        // 更新现有角色
        final updatedCharacter = CharacterCard(
          id: widget.character!.id,
          name: _nameController.text,
          avatar: _avatarPath,
          background: _backgroundPath,
          backgroundOpacity: _backgroundOpacity,
          description: _descriptionController.text,
          personality: _personalityController.text,
          scenario: _scenarioController.text,
          firstMessage: _firstMessageController.text,
          exampleDialogue: _exampleDialogueController.text,
          tags: tags,
          preferredModel: _preferredModel,
          createTime: widget.character!.createTime,
          isSystem: widget.character!.isSystem,
        );

        await store.updateCharacter(updatedCharacter);

        // 注意，如果是修改，还要修改已经存在的对话记录中涉及到相关角色对话的相关栏位
        final branchStore = await BranchStore.create();
        branchStore.updateSessionCharacters(updatedCharacter);
      } else {
        // 创建新角色
        await store.createCharacter(
          CharacterCard(
            id: identityHashCode(_nameController.text),
            name: _nameController.text,
            avatar: _avatarPath,
            background: _backgroundPath,
            backgroundOpacity: _backgroundOpacity,
            description: _descriptionController.text,
            personality: _personalityController.text,
            scenario: _scenarioController.text,
            firstMessage: _firstMessageController.text,
            exampleDialogue: _exampleDialogueController.text,
            tags: tags,
            preferredModel: _preferredModel,
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      commonExceptionDialog(context, '保存角色', '保存失败: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑角色' : '创建角色'),
        actions: [
          if (isSaving)
            Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: isSaving ? null : _saveCharacter,
            child: Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child:
            ScreenHelper.isDesktop()
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
      ),
    );
  }

  // 桌面端布局 - 使用两列布局提供更好的空间利用
  Widget _buildDesktopLayout() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧 - 基本信息与预览
          Container(
            width: 320,
            padding: EdgeInsets.only(right: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像选择
                  Center(child: _buildAvatarSelector()),
                  SizedBox(height: 24),

                  // 背景选择
                  _buildBackgroundSelector(),
                  SizedBox(height: 24),

                  // 偏好模型选择
                  _buildModelSelect(),
                ],
              ),
            ),
          ),

          // 分隔线
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.grey.shade300,
            margin: EdgeInsets.symmetric(horizontal: 12),
          ),

          // 右侧 - 表单内容
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildBaseOptions(),

                  SizedBox(height: 16),

                  // 高级设置
                  Text(
                    '高级设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // 将高级设置展开为独立表单项
                  ..._buildAdvanceOptions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局
  Widget _buildMobileLayout() {
    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        // 头像选择
        _buildAvatarSelector(),
        SizedBox(height: 16),

        // 背景选择
        _buildBackgroundSelector(),
        SizedBox(height: 16),

        // 基础设置
        ..._buildBaseOptions(), SizedBox(height: 16),

        // 偏好模型选择
        _buildModelSelect(),
        SizedBox(height: 16),

        // 高级设置
        ExpansionTile(
          title: Text('高级设置', style: TextStyle(fontSize: 14)),
          initiallyExpanded: _isEditing,
          children: _buildAdvanceOptions(),
        ),
      ],
    );
  }

  List<Widget> _buildBaseOptions() {
    return [
      Padding(
        padding: EdgeInsets.only(left: 8, bottom: 16),
        child: Text('角色ID: ${widget.character?.id ?? '<等待创建>'}'),
      ),

      // 基本信息
      TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: '角色名称*',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入角色名称';
          }
          return null;
        },
      ),
      SizedBox(height: 16),

      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: '角色描述*',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入角色描述';
          }
          return null;
        },
      ),
      SizedBox(height: 16),
    ];
  }

  Widget _buildModelSelect() {
    return // 模型选择
    Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade600),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        title: Text('偏好模型', style: TextStyle(fontSize: 14)),
        subtitle: Text(
          " ${CP_NAME_MAP[_preferredModel?.platform] ?? '未设置平台'} - ${_preferredModel?.name ?? '未设置模型'}",
          style: TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectModel,
      ),
    );
  }

  List<Widget> _buildAdvanceOptions() {
    return [
      TextFormField(
        controller: _personalityController,
        decoration: InputDecoration(
          labelText: '性格特点',
          border: OutlineInputBorder(),
          hintText: '例如：友好、耐心、幽默...',
        ),
        maxLines: 2,
      ),
      SizedBox(height: 16),
      TextFormField(
        controller: _scenarioController,
        decoration: InputDecoration(
          labelText: '场景设定',
          border: OutlineInputBorder(),
          hintText: '角色所处的环境或背景...',
        ),
        maxLines: 2,
      ),
      SizedBox(height: 16),
      TextFormField(
        controller: _firstMessageController,
        decoration: InputDecoration(
          labelText: '首条消息',
          border: OutlineInputBorder(),
          hintText: '角色的第一句话...',
        ),
        maxLines: 2,
      ),
      SizedBox(height: 16),
      TextFormField(
        controller: _exampleDialogueController,
        decoration: InputDecoration(
          labelText: '对话示例',
          border: OutlineInputBorder(),
          hintText: '示例对话，帮助AI理解角色的说话方式...',
        ),
        maxLines: 4,
      ),
      SizedBox(height: 16),
      TextFormField(
        controller: _tagsController,
        decoration: InputDecoration(
          labelText: '标签',
          border: OutlineInputBorder(),
          hintText: '用逗号分隔，例如：幽默,科幻,助手',
        ),
      ),
      SizedBox(height: 16),
    ];
  }

  // 头像选择器
  Widget _buildAvatarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showAvatarOrBgOptions('avatar'),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: buildAvatarClipOval(_avatarPath),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '点击头像选择',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // 背景选择器
  Widget _buildBackgroundSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '角色专属背景',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),

        Row(
          children: [
            GestureDetector(
              onTap: () => _showAvatarOrBgOptions('bg'),
              child: Container(
                width: 144,
                height: 81,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildBgChild(),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '点击左侧图片\n设置角色背景',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            if (_backgroundPath != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    _backgroundPath = null;
                  });
                },
                tooltip: '移除背景',
              ),
          ],
        ),
        if (_backgroundPath != null) ...[
          SizedBox(height: 12),
          Text('背景透明度', style: TextStyle(fontSize: 13)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _backgroundOpacity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _backgroundOpacity = value;
                    });
                  },
                ),
              ),
              Text(
                '${((_backgroundOpacity * 100).toInt())}%',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBgChild() {
    return _backgroundPath == null
        ? Center(
          child: Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
        )
        : Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: _backgroundOpacity,
                child: buildNetworkOrFileImage(
                  _backgroundPath!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.all(4),
                // 用户的字体颜色和AI响应的字体颜色不一样
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '用户消息: ${(_backgroundOpacity * 100).toInt()}%',
                      style: TextStyle(color: _colorConfig.userTextColor),
                    ),
                    Text(
                      '思考内容: ${(_backgroundOpacity * 100).toInt()}%',
                      style: TextStyle(color: _colorConfig.aiThinkingTextColor),
                    ),
                    Text(
                      '正常回复: ${(_backgroundOpacity * 100).toInt()}%',
                      style: TextStyle(color: _colorConfig.aiNormalTextColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }

  // 显示头像或背景选项
  void _showAvatarOrBgOptions(String type) {
    Widget list = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(padding: EdgeInsets.all(24), child: Text("选择图片来源")),

        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('相册'),
          onTap: () {
            Navigator.pop(context);
            _pickImageFromCameraOrGallery(type, CusImageSource.gallery);
          },
        ),
        if (ScreenHelper.isMobile())
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCameraOrGallery(type, CusImageSource.camera);
            },
          ),
        ListTile(
          leading: const Icon(Icons.link),
          title: const Text('网络图片地址'),
          onTap: () {
            Navigator.pop(context);
            _inputNetworkImageUrl(type);
          },
        ),
      ],
    );

    ScreenHelper.isDesktop()
        ? showDialog(
          context: context,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            return AlertDialog(
              content: SizedBox(width: screenWidth * 0.6, child: list),
            );
          },
        )
        : showModalBottomSheet(context: context, builder: (context) => list);
  }

  // 从相册选择图片或相机拍照
  // type: avatar 头像, bg 背景
  Future<void> _pickImageFromCameraOrGallery(
    String type,
    CusImageSource source,
  ) async {
    File? pickedFile;
    // 相册
    if (source == CusImageSource.gallery) {
      pickedFile = await ImagePickerHelper.pickSingleImage();
    } else {
      pickedFile = await ImagePickerHelper.takePhotoAndSave();
    }

    if (pickedFile != null) {
      // 复制图片到应用目录
      final appDir = await getAppHomeDirectory();
      final fileName =
          '${type == 'avatar' ? 'character_avatar' : 'character_bg'}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 创建角色图片文件夹路径
      final Directory fileDir = Directory('${appDir.path}/character_images');

      // 检查文件夹是否存在，如果不存在则创建
      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
      }

      final savedImage = await File(
        pickedFile.path,
      ).copy('${fileDir.path}/$fileName');

      setState(() {
        if (type == 'avatar') {
          _avatarPath = savedImage.path;
        } else {
          _backgroundPath = savedImage.path;
        }
      });
    }
  }

  // 输入网络图片地址
  void _inputNetworkImageUrl(String type) async {
    final textController = TextEditingController();
    var imageUrl = textController.text;

    var rst = await showDialog(
      context: context,
      builder: (context) {
        // 使用 StatefulBuilder 实现对话框内部状态管理
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('输入网络图片地址'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/image.jpg',
                        labelText: '图片URL',
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (value) {
                        // 文本变化时触发界面更新
                        setState(() {
                          imageUrl = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 预览区域
                    // 效果不好，桌面端也预览报错
                    // if (url.isNotEmpty) imagePreview,
                    if (imageUrl.isNotEmpty) buildNetworkOrFileImage(imageUrl),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (rst == true) {
      // 更新外部状态
      setState(() {
        if (type == 'avatar') {
          _avatarPath = imageUrl;
        } else {
          _backgroundPath = imageUrl;
        }
      });
    }
  }
}
