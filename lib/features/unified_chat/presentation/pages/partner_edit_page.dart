import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/get_dir.dart';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/models/unified_chat_partner.dart';
import '../../data/models/unified_model_spec.dart';

/// 搭档编辑页(新建/编辑共用)
/// 2026-09-07 由 AddPartnerDialog 弹窗改为独立页面：
/// 字段多、提示词长，页面可完整展示与编辑；桌面端两列布局，移动端单列
/// 头像与专属背景支持三种来源：相册/拍照(仅移动端)/网络图片地址(旧版能力回迁)
class PartnerEditPage extends StatefulWidget {
  final UnifiedChatPartner? partner;

  const PartnerEditPage({super.key, this.partner});

  @override
  State<PartnerEditPage> createState() => _PartnerEditPageState();
}

class _PartnerEditPageState extends State<PartnerEditPage> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();

  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _descriptionController;
  late TextEditingController _personalityController;
  late TextEditingController _scenarioController;
  late TextEditingController _exampleDialogueController;
  late TextEditingController _firstMessageController;
  late TextEditingController _tagsController;

  // 对话参数(2026-09-09 混合方案：留空=未设置→不传，由平台API默认值生效)
  late TextEditingController _temperatureController;
  late TextEditingController _topPController;
  late TextEditingController _maxTokensController;

  // 上下文消息数(2026-09-09 留空=不限制，携带全部历史避免记忆丢失)
  late TextEditingController _contextLengthController;

  /// 头像(支持本地路径/网络链接)
  String? _avatarPath;

  /// 专属背景(支持本地路径/网络链接)
  String? _backgroundPath;

  /// 专属背景不透明度
  double _backgroundOpacity = 0.35;

  /// 偏好模型id(null=不指定)
  String? _preferredModelId;

  /// 2026-09-07 偏好模型候选项：直读数据库"平台管理中已激活平台下的全部对话模型"，
  /// 不再依赖 viewModel.availableModels——后者只保留"已存API Key平台"的模型，
  /// 且受 viewModel 初始化/刷新时机影响，曾出现配置了模型仍显示"暂无可用模型"的问题
  List<UnifiedModelSpec> _modelOptions = [];

  /// 平台id -> 平台显示名(下拉项标注来源平台)
  Map<String, String> _platformNames = {};

  bool _advancedExpanded = false;
  bool _isSaving = false;

  bool get _isEditing => widget.partner != null;

  @override
  void initState() {
    super.initState();
    final p = widget.partner;
    _nameController = TextEditingController(text: p?.name ?? '');
    _promptController = TextEditingController(text: p?.prompt ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _personalityController = TextEditingController(text: p?.personality ?? '');
    _scenarioController = TextEditingController(text: p?.scenario ?? '');
    _exampleDialogueController = TextEditingController(
      text: p?.exampleDialogue ?? '',
    );
    _firstMessageController = TextEditingController(
      text: p?.firstMessage ?? '',
    );
    _tagsController = TextEditingController(text: p?.tagList.join(','));
    _temperatureController = TextEditingController(
      text: p?.temperature?.toString() ?? '',
    );
    _topPController = TextEditingController(text: p?.topP?.toString() ?? '');
    _maxTokensController = TextEditingController(
      text: p?.maxTokens?.toString() ?? '',
    );
    _contextLengthController = TextEditingController(
      text: p?.contextMessageLength?.toString() ?? '',
    );
    _avatarPath = p?.avatarUrl;
    _backgroundPath = p?.background;
    _backgroundOpacity = p?.backgroundOpacity ?? 0.35;
    _preferredModelId = p?.preferredModelId;
    _advancedExpanded = p?.hasStructuredProfile == true;
    _loadModelOptions();
  }

  /// 加载平台管理中已激活平台下的全部对话模型(仅cc类型)
  Future<void> _loadModelOptions() async {
    try {
      final platforms = await _chatDao.getPlatformSpecs(isActive: true);
      _platformNames = {
        for (final plat in platforms) plat.id: plat.displayName,
      };
      _modelOptions = (await _chatDao.getModelSpecs(
        platformIds: platforms.map((plat) => plat.id).toList(),
      )).where((m) => m.type == UnifiedModelType.cc).toList();
    } catch (_) {
      _modelOptions = [];
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _scenarioController.dispose();
    _exampleDialogueController.dispose();
    _firstMessageController.dispose();
    _tagsController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _maxTokensController.dispose();
    _contextLengthController.dispose();
    super.dispose();
  }

  bool _hasStructuredFields() {
    return _descriptionController.text.trim().isNotEmpty ||
        _personalityController.text.trim().isNotEmpty ||
        _scenarioController.text.trim().isNotEmpty ||
        _exampleDialogueController.text.trim().isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      ToastUtils.showInfo('请输入搭档名称');
      return;
    }

    final hasStructured = _hasStructuredFields();

    // 未配置结构化人设时，人物设定必填(轻量搭档模式)
    if (!hasStructured && _promptController.text.trim().isEmpty) {
      ToastUtils.showInfo('请输入人物设定，或展开高级设置填写角色卡信息');
      return;
    }

    // 2026-09-09 解析对话参数(留空=null不传→平台默认；非法值提示并中断)
    double? temperature;
    final tText = _temperatureController.text.trim();
    if (tText.isNotEmpty) {
      final v = double.tryParse(tText);
      if (v == null || v < 0 || v > 2) {
        ToastUtils.showInfo('温度需为0~2之间的数字');
        return;
      }
      temperature = v;
    }
    double? topP;
    final pText = _topPController.text.trim();
    if (pText.isNotEmpty) {
      final v = double.tryParse(pText);
      if (v == null || v < 0 || v > 1) {
        ToastUtils.showInfo('top_p需为0~1之间的数字');
        return;
      }
      topP = v;
    }
    int? maxTokens;
    final mText = _maxTokensController.text.trim();
    if (mText.isNotEmpty) {
      final v = int.tryParse(mText);
      if (v == null || v <= 0) {
        ToastUtils.showInfo('最大Token需为正整数');
        return;
      }
      maxTokens = v;
    }

    // 2026-09-09 上下文消息数(留空=null不限制；0=仅最新一条；正数=最近N条)
    int? contextMessageLength;
    final cText = _contextLengthController.text.trim();
    if (cText.isNotEmpty) {
      final v = int.tryParse(cText);
      if (v == null || v < 0) {
        ToastUtils.showInfo('上下文消息数需为非负整数(留空=不限制)');
        return;
      }
      contextMessageLength = v;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final personality = _personalityController.text.trim();
      final scenario = _scenarioController.text.trim();
      final exampleDialogue = _exampleDialogueController.text.trim();
      final firstMessage = _firstMessageController.text.trim();
      final background = _backgroundPath?.trim();

      // 标签：逗号分隔转JSON数组字符串
      String? tagsJson;
      final tagsText = _tagsController.text.trim();
      if (tagsText.isNotEmpty) {
        final tags = tagsText
            .split(RegExp(r'[,，]'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (tags.isNotEmpty) tagsJson = jsonEncode(tags);
      }

      final now = DateTime.now();
      final partner = UnifiedChatPartner(
        id: widget.partner?.id ?? const Uuid().v4(),
        name: name,
        // 配置了结构化人设时自动生成系统提示词(与旧版角色卡一致)，否则用填写的Prompt
        prompt: hasStructured
            ? UnifiedChatPartner(
                id: 'tmp',
                name: name,
                prompt: '',
                description: description,
                personality: personality,
                scenario: scenario,
                exampleDialogue: exampleDialogue,
                tags: tagsJson,
                createdAt: now,
                updatedAt: now,
              ).generateSystemPrompt()
            : _promptController.text.trim(),
        avatarUrl: _avatarPath?.trim().isEmpty ?? true
            ? null
            : _avatarPath!.trim(),
        isBuiltIn: widget.partner?.isBuiltIn ?? false,
        isActive: true,
        isFavorite: widget.partner?.isFavorite ?? false,
        createdAt: widget.partner?.createdAt ?? now,
        updatedAt: now,
        contextMessageLength: contextMessageLength,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        description: description.isEmpty ? null : description,
        personality: personality.isEmpty ? null : personality,
        scenario: scenario.isEmpty ? null : scenario,
        firstMessage: firstMessage.isEmpty ? null : firstMessage,
        exampleDialogue: exampleDialogue.isEmpty ? null : exampleDialogue,
        tags: tagsJson,
        preferredModelId: _preferredModelId,
        background: (background?.isEmpty ?? true) ? null : background,
        backgroundOpacity: (background?.isEmpty ?? true)
            ? null
            : _backgroundOpacity,
      );

      // 保存由列表页完成后刷新(此处仅回传成功标记)
      if (!mounted) return;
      Navigator.of(context).pop(partner);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2026-09-10 与其他桌面端页面统一：CusContentWidth.form包在Scaffold
    // 外层，整个页面(AppBar+内容)限宽720居中，窄屏原样铺满
    return CusContentWidth.form(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '编辑搭档' : '创建搭档'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: Text(_isEditing ? '保存' : '创建'),
            ),
          ],
        ),
        body: SafeArea(
          child: ScreenHelper.isDesktop()
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
        ),
      ),
    );
  }

  /// 桌面两列布局：左列媒体与模型配置，右列表单(对齐旧版角色编辑页)
  Widget _buildDesktopLayout() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 320,
            padding: const EdgeInsets.only(right: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildAvatarSelector()),
                  const SizedBox(height: 24),
                  _buildBackgroundSelector(),
                  const SizedBox(height: 24),
                  _buildLabel('偏好模型'),
                  _buildPreferredModelSelector(),
                  const SizedBox(height: 16),
                  // 2026-09-09 对话参数(可选，留空=平台API默认值)
                  ..._buildDialogParamsFields(),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: double.infinity,
            color: Theme.of(context).dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('搭档名称'),
                  _buildNameField(),
                  _buildLabel('人物设定（Prompt）'),
                  _buildPromptField(),
                  const SizedBox(height: 16),
                  Text(
                    '角色卡高级设置',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ..._buildAdvancedFields(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 移动单列布局：高级设置折叠
  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAvatarSelector(),
        const SizedBox(height: 16),
        _buildBackgroundSelector(),
        const SizedBox(height: 16),
        _buildLabel('搭档名称'),
        _buildNameField(),
        _buildLabel('人物设定（Prompt）'),
        _buildPromptField(),
        const SizedBox(height: 8),
        ExpansionTile(
          title: const Text('角色卡高级设置', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            '结构化人设/开场白/偏好模型',
            style: TextStyle(fontSize: 12),
          ),
          initiallyExpanded: _advancedExpanded,
          children: [
            ..._buildAdvancedFields(),
            _buildLabel('偏好模型'),
            _buildPreferredModelSelector(),
            const SizedBox(height: 16),
            // 2026-09-09 对话参数(可选，留空=平台API默认值)
            ..._buildDialogParamsFields(),
            const SizedBox(height: 16),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 2026-09-09 对话参数编辑区(可选)：
  /// 留空=未设置→请求不带该参数→各平台API默认值生效；
  /// 填写则作为该搭档的显式偏好(选择搭档开始新对话时应用)
  List<Widget> _buildDialogParamsFields() {
    return [
      Text(
        '对话参数(可选)',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        '留空使用各平台API默认值；设置后选择该搭档开始新对话时生效',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      _buildLabel('温度 temperature (0~2，越高越有创造性)'),
      TextField(
        controller: _temperatureController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8),
          hintText: '留空使用平台默认',
          isDense: true,
        ),
      ),
      _buildLabel('top_p (0~1，核采样阈值)'),
      TextField(
        controller: _topPController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8),
          hintText: '留空使用平台默认',
          isDense: true,
        ),
      ),
      _buildLabel('最大Token (单次回复长度上限)'),
      TextField(
        controller: _maxTokensController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8),
          hintText: '留空使用平台默认',
          isDense: true,
        ),
      ),
      _buildLabel('上下文消息数 (携带的历史消息条数)'),
      TextField(
        controller: _contextLengthController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(8),
          hintText: '留空=不限制(携带全部历史)；0=仅最新一条',
          isDense: true,
        ),
      ),
    ];
  }

  List<Widget> _buildAdvancedFields() {
    return [
      _buildLabel('角色背景描述'),
      _buildAdvancedField(_descriptionController, '角色的身份、经历、知识背景等', 3),
      _buildLabel('性格特点'),
      _buildAdvancedField(_personalityController, '角色的性格、说话风格等', 2),
      _buildLabel('场景设定'),
      _buildAdvancedField(_scenarioController, '对话发生的场景/世界观', 2),
      _buildLabel('对话示例'),
      _buildAdvancedField(_exampleDialogueController, '示例对话，帮助模型理解角色语气', 4),
      _buildLabel('开场白'),
      _buildAdvancedField(_firstMessageController, '开始新对话时自动发送的开场白(不调用模型)', 3),
      _buildLabel('标签(逗号分隔)'),
      _buildAdvancedField(_tagsController, '如: 虚拟, 角色扮演, 助手', 1),
    ];
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(8),
        hintText: '给你的搭档起个名字',
      ),
    );
  }

  Widget _buildPromptField() {
    return TextField(
      controller: _promptController,
      maxLines: 6,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(8),
        hintText: _hasStructuredFields()
            ? '已配置角色卡信息，Prompt将自动生成(可留空)'
            : '描述你的搭档的角色、性格、专长等...',
      ),
    );
  }

  Widget _buildAdvancedField(
    TextEditingController controller,
    String hint,
    int maxLines,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(8),
          hintText: hint,
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ==================== 头像/背景选择(相册/拍照/网络地址三模式) ====================

  /// 头像选择器：80x80 圆形，点击换图
  Widget _buildAvatarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showImageSourceOptions('avatar'),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _avatarPath == null || _avatarPath!.trim().isEmpty
                  ? const Icon(Icons.add_photo_alternate, size: 32)
                  : buildNetworkOrFileImage(_avatarPath!, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '点击头像选择图片',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
      ],
    );
  }

  /// 背景选择器：144x81 缩略图 + 透明度滑杆 + 移除
  Widget _buildBackgroundSelector() {
    final hasBg = _backgroundPath != null && _backgroundPath!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('专属背景'),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showImageSourceOptions('background'),
              child: Container(
                width: 144,
                height: 81,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: hasBg
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildNetworkOrFileImage(
                          _backgroundPath!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasBg ? '点击图片更换背景' : '点击设置该搭档对话时的专属背景',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasBg)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => setState(() => _backgroundPath = null),
                tooltip: '移除背景',
              ),
          ],
        ),
        if (hasBg) ...[
          const SizedBox(height: 12),
          const Text('背景不透明度', style: TextStyle(fontSize: 13)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _backgroundOpacity,
                  min: 0.1,
                  max: 1.0,
                  label: '${(_backgroundOpacity * 100).toInt()}%',
                  onChanged: (v) => setState(() => _backgroundOpacity = v),
                ),
              ),
              Text('${(_backgroundOpacity * 100).toInt()}%'),
            ],
          ),
        ],
      ],
    );
  }

  /// 弹出图片来源选择：相册/拍照(仅移动端)/网络图片地址
  void _showImageSourceOptions(String type) {
    Widget list = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(padding: EdgeInsets.all(24), child: Text('选择图片来源')),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('相册'),
          onTap: () {
            Navigator.pop(context);
            _pickImage(type, CusImageSource.gallery);
          },
        ),
        if (ScreenHelper.isMobile())
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(type, CusImageSource.camera);
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

    if (ScreenHelper.isDesktop()) {
      // 2026-09-10 弹窗宽度统一：桌面此前0.4倍窗口宽，归一到
      // Align+CB(dialogWidth)模式
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CusContentWidth.dialogWidth,
              ),
              child: AlertDialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                content: SizedBox(width: double.maxFinite, child: list),
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (sheetContext) => SafeArea(child: list),
      );
    }
  }

  /// 相册/拍照选图，并复制到应用角色图片目录持久化
  Future<void> _pickImage(String type, CusImageSource source) async {
    File? pickedFile;
    if (source == CusImageSource.gallery) {
      pickedFile = await ImagePickerUtils.pickSingleImage();
    } else {
      pickedFile = await ImagePickerUtils.takePhotoAndSave();
    }

    if (pickedFile == null) return;

    try {
      // 复制图片到应用角色目录(加类型前缀避免重复覆盖)
      final fileDir = await getCharacterDir();
      final typePrefix = type == 'avatar' ? 'partner_avatar' : 'partner_bg';
      final fileName =
          '${typePrefix}_${pickedFile.path.split(Platform.pathSeparator).last}';
      final savedImage = await File(
        pickedFile.path,
      ).copy('${fileDir.path}${Platform.pathSeparator}$fileName');

      if (!mounted) return;
      setState(() {
        if (type == 'avatar') {
          _avatarPath = savedImage.path;
        } else {
          _backgroundPath = savedImage.path;
        }
      });
    } catch (e) {
      if (mounted) ToastUtils.showError('保存图片失败: $e');
    }
  }

  /// 输入网络图片地址(带实时预览)
  Future<void> _inputNetworkImageUrl(String type) async {
    final textController = TextEditingController();
    var imageUrl = '';

    final rst = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                      onChanged: (value) =>
                          setDialogState(() => imageUrl = value),
                    ),
                    const SizedBox(height: 16),
                    if (imageUrl.isNotEmpty) buildNetworkOrFileImage(imageUrl),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (rst == true && mounted) {
      setState(() {
        if (type == 'avatar') {
          _avatarPath = imageUrl;
        } else {
          _backgroundPath = imageUrl;
        }
      });
    }
  }

  /// 偏好模型下拉(选择该搭档时自动切换到该模型，见viewmodel.selectPartner)
  Widget _buildPreferredModelSelector() {
    if (_modelOptions.isEmpty) {
      return const Text(
        '暂无可用模型：请先在「平台管理」激活平台并添加对话模型',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    return DropdownButtonFormField<String?>(
      initialValue: _modelOptions.any((m) => m.id == _preferredModelId)
          ? _preferredModelId
          : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        isDense: true,
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('不指定')),
        ..._modelOptions.map((m) {
          final platformName = _platformNames[m.platformId];
          return DropdownMenuItem<String?>(
            value: m.id,
            child: Text(
              platformName == null || platformName.isEmpty
                  ? m.displayName
                  : '${m.displayName} · $platformName',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (v) => setState(() => _preferredModelId = v),
    );
  }
}
