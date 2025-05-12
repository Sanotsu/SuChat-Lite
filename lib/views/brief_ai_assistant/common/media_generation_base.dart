import 'dart:io';
import 'package:flutter/material.dart';

import '../../../common/components/toast_utils.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/image_picker_helper.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../services/model_manager_service.dart';
import '../../../services/voice_generation_service.dart';
import '../../../models/brief_ai_tools/media_generation_history/media_generation_history.dart';

abstract class MediaGenerationBase extends StatefulWidget {
  const MediaGenerationBase({super.key});
}

abstract class MediaGenerationBaseState<T extends MediaGenerationBase>
    extends State<T> {
  // 提示词控制器
  final TextEditingController promptController = TextEditingController();
  // 数据库帮助类
  final DBBriefAIToolHelper dbHelper = DBBriefAIToolHelper();
  // 模型列表
  List<CusBriefLLMSpec> modelList = [];
  // 选中的模型
  CusBriefLLMSpec? selectedModel;
  // 参考图片
  File? referenceImage;
  // 是否正在生成
  bool isGenerating = false;

  // 子类需要实现的方法
  List<LLModelType> get mediaTypes;
  String get title;
  String get note;
  Future<void> generate();
  Widget buildMediaOptions();
  Widget buildGeneratedList();

  // 可用的音色列表
  List<AliyunVoiceType> voiceOptions =
      VoiceGenerationService.getV1AvailableVoices() +
      VoiceGenerationService.getV2AvailableVoices() +
      VoiceGenerationService.getSambertVoices() +
      VoiceGenerationService.getQwenTTSVoices();

  // 选择的音色
  late AliyunVoiceType selectedVoice;

  @override
  void initState() {
    super.initState();
    selectedVoice = voiceOptions.first;

    _loadModels();
  }

  // 是否显示选择参考图片按钮和参考图片预览
  bool _isShowImageRef() {
    return [
      LLModelType.image,
      LLModelType.iti,
      LLModelType.video,
      LLModelType.itv,
    ].contains(selectedModel?.modelType);
  }

  // 加载可用模型
  Future<void> _loadModels() async {
    final models = await ModelManagerService.getAvailableModelByTypes(
      mediaTypes,
    );

    if (!mounted) return;
    setState(() {
      modelList = models;
      selectedModel = models.isNotEmpty ? models.first : null;

      // 测试自用，如果有的话，默认把qwen-tts放在第一个
      if (selectedModel?.modelType == LLModelType.tts) {
        var temp = models.where((e) => e.model.contains("qwen-tts")).toList();
        if (temp.isNotEmpty) {
          selectedModel = temp.first;
          voiceOptions = VoiceGenerationService.getQwenTTSVoices();
          selectedVoice = voiceOptions.first;
        }
      }
    });
  }

  Future<void> pickReferenceImage() async {
    final image = await ImagePickerHelper.pickSingleImage();

    if (image != null) {
      setState(() => referenceImage = File(image.path));
    }
  }

  // 检查生成前的必要条件
  bool checkGeneratePrerequisites() {
    if (selectedModel == null) {
      ToastUtils.showError('请先选择模型');
      return false;
    }

    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      ToastUtils.showError('请输入提示词');
      return false;
    }

    return true;
  }

  // 参考图片和生成按钮布局
  Widget buildReferenceImageAndButton() {
    return Row(
      children: [
        // 选择参考图片按钮
        if (_isShowImageRef()) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : pickReferenceImage,
              icon: const Icon(Icons.image),
              label: const Text('选择参考图片'),
            ),
          ),
          SizedBox(width: 8),
        ],
        // 生成按钮
        Expanded(
          child: ElevatedButton(
            onPressed: isGenerating ? null : generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child:
                isGenerating
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text('生成'),
          ),
        ),
      ],
    );
  }

  // 显示参考图片预览
  Widget buildReferenceImagePreview() {
    if (referenceImage == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(4),
      child: Stack(
        children: [
          Image.file(
            referenceImage!,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              child: Icon(Icons.close, size: 20),
              onTap: () => setState(() => referenceImage = null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: buildAppBarActions()),
      body:
          ScreenHelper.isDesktop()
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
    );
  }

  // 桌面布局 - 左右结构
  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧输入区域
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 配置区域
                Row(
                  children: [
                    // 模型选择
                    buildModelSelector(),
                    // 媒体选项
                    buildMediaOptions(),
                  ],
                ),

                SizedBox(height: 16),

                // 参考图片预览
                if (_isShowImageRef()) buildReferenceImagePreview(),

                SizedBox(height: 8),

                // 提示词输入 - 这里不使用Expanded包装，改为Flexible
                Flexible(
                  child: TextField(
                    controller: promptController,
                    maxLines: ScreenHelper.isDesktop() ? 10 : 5,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '提示词',
                      hintText: '请输入描述',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    enabled: !isGenerating,
                  ),
                ),

                SizedBox(height: 16),

                // 生成按钮区域
                buildReferenceImageAndButton(),
              ],
            ),
          ),

          // 中间分隔线
          VerticalDivider(width: 32, thickness: 1),

          // 右侧结果区域
          Expanded(child: buildGeneratedList()),
        ],
      ),
    );
  }

  // 移动布局 - 上下结构
  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // 模型选择
                buildModelSelector(),

                // 媒体选项(由子类实现)
                buildMediaOptions(),
              ],
            ),
          ),

          Row(
            children: [
              // 参考图片预览
              if (_isShowImageRef()) buildReferenceImagePreview(),

              // 提示词输入
              Expanded(child: buildPromptInput()),
            ],
          ),

          // 参考图片和生成按钮
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: buildReferenceImageAndButton(),
          ),

          // 生成的媒体列表(由子类实现)
          Expanded(child: buildGeneratedList()),
        ],
      ),
    );
  }

  /// 子类可以覆盖的方法，不需覆盖就用父类的

  // 顶部栏按钮
  List<Widget> buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.photo_library_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => buildManagerScreen()),
          );
        },
      ),
      IconButton(
        onPressed: () {
          ScreenHelper.isDesktop()
              ? commonMarkdwonHintDialog(context, "$title使用说明", note)
              : commonMDHintModalBottomSheet(context, "$title使用说明", note);
        },
        icon: const Icon(Icons.info_outline),
      ),
    ];
  }

  // 媒体管理页面
  Widget buildManagerScreen();

  // 模型选择器
  Widget buildModelSelector() {
    return Expanded(
      child: buildDropdownButton2<CusBriefLLMSpec?>(
        value: selectedModel,
        items: modelList,
        height: 48,
        hintLabel: "选择模型",
        alignment: Alignment.centerLeft,
        onChanged: isGenerating ? null : modelChanged,
        itemToString:
            (e) =>
                "${CP_NAME_MAP[(e as CusBriefLLMSpec).platform]} - ${e.name}",
      ),
    );
  }

  modelChanged(CusBriefLLMSpec? value) async {
    setState(() {
      selectedModel = value!;
    });
  }

  // 提示词输入框
  Widget buildPromptInput() {
    return TextField(
      controller: promptController,
      maxLines: 5,
      style: TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: '提示词',
        hintText: '请输入描述',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      enabled: !isGenerating,
    );
  }

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  // =============================================
  // 以下是添加的公共任务卡片组件方法
  // =============================================

  /// 构建通用的任务状态指示器
  Widget buildTaskStatusIndicator(MediaGenerationHistory task) {
    Color color;
    IconData icon;
    String label;

    if (task.isSuccess == true) {
      color = Colors.green;
      icon = Icons.check_circle;
      label = '完成';
    } else if (task.isFailed == true) {
      color = Colors.red;
      icon = Icons.error;
      label = '失败';
    } else if (task.isProcessing == true) {
      color = Colors.blue;
      icon = Icons.hourglass_empty;
      label = '处理中';
    } else {
      color = Colors.orange;
      icon = Icons.warning;
      label = '未知';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  /// 构建通用的任务卡片
  ///
  /// [task] - 媒体生成任务记录
  /// [onTap] - 点击卡片时的回调
  /// [onLongPress] - 长按卡片时的回调
  /// [mediaPreview] - 媒体预览小部件，如图片缩略图或视频图标
  /// [isGrid] - 是否使用网格布局
  Widget buildMediaTaskCard({
    required MediaGenerationHistory task,
    required Function() onTap,
    required Function() onLongPress,
    required Widget mediaPreview,
    bool isGrid = false,
  }) {
    // 列表视图时的卡片内容
    Widget listCardChild = Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          // 媒体预览
          mediaPreview,
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${CP_NAME_MAP[task.llmSpec.platform] ?? ''} ${task.llmSpec.model}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    buildTaskStatusIndicator(task),
                  ],
                ),
                Text(task.gmtCreate.toString(), style: TextStyle(fontSize: 12)),
                // 提示词
                SizedBox(
                  height: 40,
                  child: Text(
                    task.prompt,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(5),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: isGrid ? mediaPreview : listCardChild,
      ),
    );
  }

  /// 创建通用的确认删除对话框
  Future<bool?> showDeleteTaskConfirmDialog(
    BuildContext context,
    String mediaType,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('删除$mediaType生成任务', style: TextStyle(fontSize: 16)),
            content: Text(
              '删除后，$mediaType生成任务记录将不再显示，但不会影响已保存的$mediaType文件。',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('取消', style: TextStyle(fontSize: 14)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('确定', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
    );
  }
}
