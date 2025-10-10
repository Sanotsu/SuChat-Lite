import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/models/unified_model_spec.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'model_selector_dialog.dart';
import 'chat_settings_dialog.dart';
import 'image_generation_settings_dialog.dart';
import 'speech_synthesis_settings_dialog.dart';
import 'model_type_icon.dart';

/// 聊天输入组件
/// 包含预览区域、输入区域、工具按钮区域
class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({super.key});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  // 附件状态
  final List<File> _selectedImages = [];
  final List<File> _selectedFiles = [];
  File? _selectedAudio;
  File? _selectedVideo;

  // UI状态
  bool _isToolExpanded = false;

  // 编辑状态跟踪
  String? _lastEditingMessageId;
  bool _hasSetEditingContent = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 监听编辑状态变化的方法
  void _handleEditingStateChange(UnifiedChatViewModel viewModel) {
    final currentEditingMessageId = viewModel.editingUserMessage?.id;

    if (viewModel.isUserEditingMode && viewModel.editingUserMessage != null) {
      // 只有当编辑的消息ID发生变化时才设置文本内容
      if (_lastEditingMessageId != currentEditingMessageId) {
        _lastEditingMessageId = currentEditingMessageId;
        _hasSetEditingContent = false;

        // 延迟执行以确保组件已经构建完成
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasSetEditingContent) {
            _textController.text = viewModel.editingUserMessage!.content ?? '';
            _focusNode.requestFocus();
            _hasSetEditingContent = true;
          }
        });
      }
    } else if (!viewModel.isUserEditingMode) {
      // 取消编辑时重置状态
      if (_lastEditingMessageId != null) {
        _lastEditingMessageId = null;
        _hasSetEditingContent = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _textController.clear();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        // 监听编辑状态变化
        _handleEditingStateChange(viewModel);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 0.4.sh),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 预览区域
                  if (_hasAttachments()) _buildPreviewArea(),

                  // 输入区域
                  _buildInputArea(viewModel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _hasAttachments() {
    return _selectedImages.isNotEmpty ||
        _selectedFiles.isNotEmpty ||
        _selectedAudio != null ||
        _selectedVideo != null;
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('附件预览', style: Theme.of(context).textTheme.titleSmall),
              TextButton(
                onPressed: _clearAllAttachments,
                child: const Text('清空附件'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 图片预览
          if (_selectedImages.isNotEmpty) _buildImagePreview(),

          // 文件预览
          if (_selectedFiles.isNotEmpty) _buildFilePreview(),

          // 音频预览
          if (_selectedAudio != null) _buildAudioPreview(),

          // 视频预览
          if (_selectedVideo != null) _buildVideoPreview(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilePreview() {
    return Column(
      children: _selectedFiles.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.path.split('/').last,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeFile(index),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.audiotrack,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedAudio!.path.split('/').last,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedAudio = null),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.videocam,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedVideo!.path.split('/').last,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedVideo = null),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(UnifiedChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // 文本输入区域
            Container(
              padding: EdgeInsets.only(
                left: viewModel.isUserEditingMode ? 0 : 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  // 编辑模式下显示取消按钮(注意，是取消编辑，而不是清空输入框内容，所以放在前面)
                  if (viewModel.isUserEditingMode)
                    IconButton(
                      onPressed: () {
                        viewModel.cancelEditingUserMessage();
                        _textController.clear();
                      },
                      icon: const Icon(Icons.close),
                      tooltip: '取消编辑',
                    ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: viewModel.isUserEditingMode
                            ? '编辑消息...'
                            : '输入消息...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) {
                        setState(() {});
                      },
                      onSubmitted: (text) => _sendMessage(viewModel),
                    ),
                  ),
                ],
              ),
            ),

            // 工具按钮区域
            if (_isToolExpanded) _buildToolsArea(viewModel),

            // 底部操作区域
            _buildBottomArea(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsArea(UnifiedChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Divider(height: 1),
          const SizedBox(height: 8),

          // 第一行工具
          Row(
            children: [
              if (viewModel.currentModel?.supportsVision ?? false) ...[
                _buildToolButton(
                  icon: Icons.image_outlined,
                  label: '图片',
                  onPressed: _pickImages,
                ),

                // TODO 视频、文件、语言等资源的处理还没有实现
                const SizedBox(width: 16),
                _buildToolButton(
                  icon: Icons.videocam_outlined,
                  label: '视频',
                  onPressed: _pickVideo,
                ),
                const SizedBox(width: 16),
              ],

              if (viewModel.currentModel?.type == UnifiedModelType.imageToImage)
                _buildToolButton(
                  icon: Icons.image_outlined,
                  label: '图片',
                  onPressed: _pickImages,
                ),

              // _buildToolButton(
              //   icon: Icons.attach_file_outlined,
              //   label: '文件',
              //   onPressed: _pickFiles,
              // ),
              // const SizedBox(width: 16),
              // _buildToolButton(
              //   icon: Icons.audio_file_outlined,
              //   label: '语音',
              //   onPressed: _recordAudio,
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(UnifiedChatViewModel viewModel) {
    return InkWell(
      onTap: () => _showModelSelector(viewModel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildModelTypeIconWithTooltip(viewModel.currentModel!, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                viewModel.currentModel?.displayName ?? '选择模型',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showModelSelector(UnifiedChatViewModel viewModel) {
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   builder: (context) => SizedBox(
    //     height: MediaQuery.of(context).size.height * 0.8,
    //     child: ModelSelectorBottomSheet(
    //       currentModel: viewModel.currentModel,
    //       onModelSelected: (model) {
    //         viewModel.switchModel(model);
    //         // 切换模型后，新建对话
    //         viewModel.createNewConversation();
    //       },
    //     ),
    //   ),
    // );

    showDialog(
      context: context,
      builder: (context) => ModelSelectorDialog(
        currentModel: viewModel.currentModel,
        onModelSelected: (model) {
          viewModel.switchModel(model);
          // 切换模型后，新建对话 ??? 可以考虑一下不重新创建对话
          // viewModel.createNewConversation();
        },
      ),
    );
  }

  Widget _buildBottomArea(UnifiedChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      child: Row(
        children: [
          // 添加附件内容
          if (viewModel.currentModel?.type != UnifiedModelType.textToSpeech)
            InkWell(
              onTap: () => setState(() => _isToolExpanded = !_isToolExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  _isToolExpanded
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  size: 20,
                ),
              ),
            ),

          // 联网搜索开关(暂时只让对话模型显示联网按钮)
          if (viewModel.currentModel?.type == UnifiedModelType.cc)
            InkWell(
              onTap: _canToggleWebSearch(viewModel)
                  ? () => viewModel.toggleWebSearch()
                  : () => ToastUtils.showInfo("该平台或模型不支持联网搜索"),
              onLongPress: () => _showTooltipDialog(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.language,
                  size: 20,
                  color:
                      viewModel.hasAvailableSearchTools() &&
                          viewModel.isWebSearchEnabled
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),

          // 高级设置按钮
          InkWell(
            onTap: () => _showAdvancedSettings(viewModel),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.tune, size: 20),
            ),
          ),
          Expanded(child: _buildModelSelector(viewModel)),

          // 发送按钮
          IconButton(
            onPressed: _canSend() && !viewModel.isStreaming
                ? () => _sendMessage(viewModel)
                : viewModel.isStreaming
                ? () => viewModel.stopStreaming()
                : null,
            icon: Icon(
              viewModel.isStreaming
                  ? Icons.stop
                  : viewModel.isUserEditingMode
                  ? Icons.check_circle
                  : Icons.arrow_circle_up,
              size: 32,
              color: _canSend() || viewModel.isStreaming
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            tooltip: viewModel.isUserEditingMode ? '完成编辑' : '发送消息',
          ),
        ],
      ),
    );
  }

  // 可启用联网搜索的条件
  // 1 模型是阿里百炼、智谱平台
  // 2 非百炼智谱平台时，模型支持工具调用，且第三方搜索工具API至少存在一个
  bool _canToggleWebSearch(UnifiedChatViewModel viewModel) {
    // 1 模型是阿里百炼、智谱平台
    bool isSupportedModel = false;
    if (viewModel.currentPlatform?.id == UnifiedPlatformId.aliyun.name ||
        viewModel.currentPlatform?.id == UnifiedPlatformId.zhipu.name) {
      isSupportedModel = true;
    }

    //  2 非百炼智谱平台时，模型支持工具调用，且第三方搜索工具API至少存在一个
    bool isSupportTool = false;
    if (!isSupportedModel) {
      isSupportTool =
          viewModel.hasAvailableSearchTools() &&
          (viewModel.currentModel?.supportsToolCalling ?? false);
    }

    // 如果是不可联网，则还需要先恢复不可联网的状态
    if (!isSupportedModel && !isSupportTool && viewModel.isWebSearchEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.toggleWebSearch();
      });
    }

    return isSupportedModel || isSupportTool;
  }

  bool _canSend() {
    return _textController.text.trim().isNotEmpty || _hasAttachments();
  }

  Future<void> _sendMessage(UnifiedChatViewModel viewModel) async {
    unfocusHandle();

    if (!_canSend() || viewModel.isStreaming) return;

    final text = _textController.text.trim();

    // 如果是编辑模式，完成编辑
    if (viewModel.isUserEditingMode) {
      await viewModel.finishEditingUserMessage(
        text,
        isWebSearch: viewModel.isWebSearchEnabled,
      );
      _textController.clear();
      _clearAllAttachments();
      return;
    }

    // 检查当前模型类型
    // 用户需要手动选择图片生成模型来使用图片生成功能
    if (viewModel.isImageGenerationModel) {
      // 如果是阿里的图生图(图像编辑)，可能必须传入图片
      if (viewModel.currentPlatform?.id == UnifiedPlatformId.aliyun.name &&
          viewModel.currentModel?.type == UnifiedModelType.imageToImage) {
        if (_selectedImages.isEmpty) {
          ToastUtils.showError('请上传图片');
          return;
        }
      }

      // 图片生成模型：输入内容作为提示词，选择的图片作为参考图
      await _handleImageGeneration(viewModel, text);
      return;
    }

    // 语音合成模型：输入内容作为要合成的文本
    if (viewModel.isSpeechSynthesisModel) {
      await _handleSpeechSynthesis(viewModel, text);
      return;
    }

    // 对于非图片生成模型，不再自动识别图片生成意图
    if (_hasAttachments()) {
      // 发送多模态消息
      await viewModel.sendMultimodalMessage(
        text,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        audio: _selectedAudio,
        video: _selectedVideo,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        isWebSearch: viewModel.isWebSearchEnabled,
      );
    } else {
      // 发送文本消息
      await viewModel.sendMessage(
        text,
        isWebSearch: viewModel.isWebSearchEnabled,
      );
    }

    // 清空输入
    _textController.clear();
    _clearAllAttachments();
    // 收起工具栏
    _isToolExpanded = false;
    // unfocusHandle();
  }

  /// 处理图片生成
  Future<void> _handleImageGeneration(
    UnifiedChatViewModel viewModel,
    String prompt,
  ) async {
    if (prompt.isEmpty) {
      ToastUtils.showError('请输入图片描述');
      return;
    }

    try {
      // 获取当前平台和模型
      final platform = viewModel.currentPlatform;
      final model = viewModel.currentModel;

      if (platform == null || model == null) {
        ToastUtils.showError('请先选择平台和模型');
        return;
      }

      // 获取当前对话的图片生成设置 (图片生成高级设置弹窗配置的参数会放在对话的extraParams属性中)
      final conversation = viewModel.currentConversation;
      final Map<String, dynamic> currentSettings =
          conversation?.extraParams?['imageGenParams'] ?? {};

      // 先深拷贝一份输入框文本和附件文件，在发送消息之前清空输入框和附件,避免发送按钮等在发送后依旧可见
      final String prompt = _textController.text.trim();
      final List<File> images = List.from(_selectedImages);

      // 清空输入框和附件(避免耗时太久输入框等未复原)
      _textController.clear();
      _clearAllAttachments();
      _isToolExpanded = false;

      // 调用专门的图片生成方法
      await viewModel.sendImageGenerationMessage(
        prompt: prompt,
        images: images,
        settings: currentSettings,
      );
    } catch (e) {
      ToastUtils.showError('图片生成失败: $e');
    }
  }

  /// 处理语音合成
  Future<void> _handleSpeechSynthesis(
    UnifiedChatViewModel viewModel,
    String text,
  ) async {
    if (text.isEmpty) {
      ToastUtils.showError('请输入要合成的文本');
      return;
    }

    try {
      // 获取当前平台和模型
      final platform = viewModel.currentPlatform;
      final model = viewModel.currentModel;

      if (platform == null || model == null) {
        ToastUtils.showError('请先选择平台和模型');
        return;
      }

      // 获取当前对话的语音合成设置
      final conversation = viewModel.currentConversation;
      final Map<String, dynamic> currentSettings =
          conversation?.extraParams?['speechSynthesisParams'] ?? {};

      // 先深拷贝一份输入框文本，在发送消息之前清空输入框
      final String textToSynthesize = _textController.text.trim();

      // 清空输入框(避免耗时太久输入框等未复原)
      _textController.clear();
      _isToolExpanded = false;

      // 调用专门的语音合成方法
      await viewModel.sendSpeechSynthesisMessage(
        text: textToSynthesize,
        settings: currentSettings,
      );
    } catch (e) {
      ToastUtils.showError('语音合成失败: $e');
    }
  }

  void _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  void _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files.map((file) => File(file.path!)));
      });
    }
  }

  // TODO 选择语音文件或者直接录制语音
  void _recordAudio() {
    ToastUtils.showError('语音录制功能待实现');
  }

  void _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _clearAllAttachments() {
    setState(() {
      _selectedImages.clear();
      _selectedFiles.clear();
      _selectedAudio = null;
      _selectedVideo = null;
    });
  }

  Future _showTooltipDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联网搜索说明', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Text(
            "1 智谱平台使用自带的联网搜索工具\n\n"
            "2 阿里百炼部分模型支持联网搜索\n\n"
            "3 硅基流动、无问芯穹等不支持联网搜索的平台，使用tools调用外部搜索工具来实现联网搜索，"
            "需要右上角‘搜索工具设置’中进行设置，且模型支持工具调用\n\n"
            "4 非百炼、智谱等自带联网搜索的平台的Qwen3、GLM4.5、DeepSeek3.1等模型，"
            "对话时最好不要同时开启联网搜索和思考模式，因为可能出现同时使用工具调用和思考模式冲突异常问题\n\n",
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAdvancedSettings(UnifiedChatViewModel viewModel) {
    final currentModel = viewModel.currentModel;
    final isImageGenerationModel =
        currentModel?.type == UnifiedModelType.textToImage ||
        currentModel?.type == UnifiedModelType.imageToImage;
    final isSpeechSynthesisModel =
        currentModel?.type == UnifiedModelType.textToSpeech;

    if (isImageGenerationModel) {
      // 显示图片生成设置对话框
      _showImageGenerationSettings(viewModel);
    } else if (isSpeechSynthesisModel) {
      // 显示语音合成设置对话框
      _showSpeechSynthesisSettings(viewModel);
    } else {
      // 显示常规聊天设置对话框
      _showChatSettings(viewModel);
    }
  }

  void _showChatSettings(UnifiedChatViewModel viewModel) {
    // 获取当前对话的设置，使用有效搭档（当前搭档或默认搭档）
    final conversation = viewModel.currentConversation;
    final effectivePartner = viewModel.effectivePartner;

    showDialog(
      context: context,
      builder: (context) => ChatSettingsDialog(
        title: conversation?.title ?? '新对话',
        systemPrompt: conversation?.systemPrompt ?? effectivePartner.prompt,
        contextMessageLength:
            conversation?.contextMessageLength ??
            effectivePartner.contextMessageLength,
        temperature:
            conversation?.temperature ?? effectivePartner.temperature ?? 0.7,
        topP: conversation?.topP ?? effectivePartner.topP ?? 1.0,
        maxTokens:
            conversation?.maxTokens ?? effectivePartner.maxTokens ?? 4096,
        isStream: conversation?.isStream ?? effectivePartner.isStream ?? true,
        // 这个启用思考不是最初的设计，就放在extraParams里，也不放在partner里
        enableThinking: conversation?.extraParams?['enableThinking'] ?? false,
        selectedPartner: viewModel.currentPartner,
        onSave: (settings) {
          viewModel.updateConversationSettings({
            ...settings,
            'partnerId': viewModel.currentPartner?.id,
          });
        },
      ),
    );
  }

  void _showImageGenerationSettings(UnifiedChatViewModel viewModel) {
    final conversation = viewModel.currentConversation;
    // 这里只取图片生成部分的参数
    final Map<String, dynamic> currentSettings =
        conversation?.extraParams?['imageGenParams'] ?? {};

    showDialog(
      context: context,
      builder: (context) => ImageGenerationSettingsDialog(
        currentPlatform: viewModel.currentPlatform,
        currentModel: viewModel.currentModel,
        currentSettings: currentSettings,
        onSave: (settings) {
          // 保存时也使用同样的参数
          viewModel.updateConversationSettings({'imageGenParams': settings});
        },
      ),
    );
  }

  void _showSpeechSynthesisSettings(UnifiedChatViewModel viewModel) {
    final conversation = viewModel.currentConversation;
    // 这里只取语音合成部分的参数
    final Map<String, dynamic> currentSettings =
        conversation?.extraParams?['speechSynthesisParams'] ?? {};

    showDialog(
      context: context,
      builder: (context) => SpeechSynthesisSettingsDialog(
        currentPlatform: viewModel.currentPlatform,
        currentModel: viewModel.currentModel,
        currentSettings: currentSettings,
        onSave: (settings) {
          // 保存时也使用同样的参数
          viewModel.updateConversationSettings({
            'speechSynthesisParams': settings,
          });
        },
      ),
    );
  }
}
