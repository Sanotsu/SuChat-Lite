import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/style/app_colors.dart';
import '../../../../core/utils/file_picker_utils.dart';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../shared/services/aliyun_paraformer_realtime_service.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../translator/data/models/aliyun_asr_realtime_models.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/services/unified_secure_storage.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'model_selector_dialog.dart';
import 'chat_settings_dialog.dart';
import 'image_generation_settings_dialog.dart';
import 'speech_synthesis_settings_dialog.dart';
import 'speech_recognition_settings_dialog.dart';
import 'model_type_icon.dart';

/// 聊天输入组件
/// 包含预览区域、输入区域、工具按钮区域
class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({super.key});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  // 文本控制器
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  String _inputText = '';

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

  /// 录音相关
  // API客户端
  late AliyunParaformerRealtimeService _apiClient;
  // 是否在录音中
  bool _isRealtimeRecording = false;
  // 录音器
  late AudioRecorder _audioRecorder;
  // 录音流订阅
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  // 实时语音识别流
  Stream<AsrRtResult>? _realtimeStream;
  // 实时语音识别订阅
  StreamSubscription<AsrRtResult>? _realtimeSubscription;

  // 长按手势相关
  bool _isDragCancelled = false;
  double _initialPanY = 0.0;
  // 上滑取消的阈值
  static const double _cancelThreshold = 100.0;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: _inputText);
    _apiClient = AliyunParaformerRealtimeService();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();

    _realtimeSubscription?.cancel();
    _audioRecorder.dispose();
    _apiClient.dispose();
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
            setState(() {
              _inputText = viewModel.editingUserMessage!.content ?? '';
            });
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
            setState(() {
              _inputText = '';
            });
          }
        });
      }
    }
  }

  // 是否有附件
  bool _hasAttachments() {
    return _selectedImages.isNotEmpty ||
        _selectedFiles.isNotEmpty ||
        _selectedAudio != null ||
        _selectedVideo != null;
  }

  // 开始实时语音识别
  void _startRealtimeRecognition() async {
    try {
      if (!(await _audioRecorder.hasPermission())) {
        ToastUtils.showError('需要录音权限才能使用语音识别功能');
        return;
      }

      setState(() {
        _isRealtimeRecording = true;
        _inputText = '';
        _textController.clear();
      });

      // 获取API密钥
      final apiKey = await UnifiedSecureStorage.getApiKey(
        UnifiedPlatformId.aliyun.name,
      );
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未找到阿里百炼平台的API密钥');
      }

      _realtimeStream = await _apiClient.initSpeechRecognition(
        apiKey: apiKey,
        // 初始化语音识别连接，语音识别模型用默认的
        modelName: "paraformer-realtime-v2",
        params: AsrRtParameter(sampleRate: 16000, format: 'pcm'),
      );

      _realtimeSubscription = _realtimeStream!.listen(
        (result) {
          if (result.isTaskStarted) {
            ToastUtils.showToast('语音识别已启动，请开始说话');
          } else if (result.isResultGenerated && !result.shouldSkip) {
            if (result.text != null && result.text!.isNotEmpty) {
              setState(() {
                _inputText = result.text!;
                _textController.text = _inputText;
              });
            }
          } else if (result.isTaskFinished) {
            ToastUtils.showToast('语音识别已完成');

            // 很多时候不会触发已完成,可能是大模型识别结果中认为句子未结束，
            // 只看到ws关闭，导致无法发送消息

            // 清理订阅
            clearRealtimeSubscription();

            // 发送消息
            if (mounted && _inputText.trim().isNotEmpty) {
              final viewModel = Provider.of<UnifiedChatViewModel>(
                context,
                listen: false,
              );
              _sendMessage(viewModel);
            }
          } else if (result.isTaskFailed) {
            ToastUtils.showError('实时识别失败: ${result.errorMessage ?? "未知错误"}');

            // 清理订阅
            clearRealtimeSubscription();

            setState(() {
              _isRealtimeRecording = false;
              _isDragCancelled = false;
            });
          }
        },
        onError: (error) {
          ToastUtils.showError('实时识别错误: $error');

          // 清理订阅
          clearRealtimeSubscription();

          setState(() {
            _isRealtimeRecording = false;
            _isDragCancelled = false;
          });
        },
      );

      // 开始录音流
      await _startRecordingStream();
    } catch (e) {
      setState(() {
        _isRealtimeRecording = false;
      });
      ToastUtils.showError('启动实时识别失败: \n$e', duration: Duration(seconds: 5));
    }
  }

  // 停止实时语音识别
  void _stopRealtimeRecognition() async {
    if (!_isRealtimeRecording) return;

    try {
      // 先停止录音
      await _stopRecording();

      // 发送结束任务指令，但不立即取消订阅
      await _apiClient.endSpeechRecognition();

      // 标记状态为已停止，但保持订阅以接收最后的结果
      setState(() {
        _isRealtimeRecording = false;
      });

      // 如果是取消操作，立即清空并取消订阅
      if (_isDragCancelled) {
        ToastUtils.showToast('语音识别已取消');
        setState(() {
          _inputText = '';
          _textController.clear();
          _isDragCancelled = false;
        });

        // 取消时立即关闭订阅
        await clearRealtimeSubscription();
      }
      // 如果是正常结束，等待task-finished事件来处理发送
      // 订阅会在收到task-finished事件后自动处理
    } catch (e) {
      setState(() {
        _isRealtimeRecording = false;
        _isDragCancelled = false;
      });
      await clearRealtimeSubscription();

      ToastUtils.showError('停止实时识别失败: $e');
    }
  }

  // 清理语音识别订阅
  Future<void> clearRealtimeSubscription() async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _realtimeStream = null;
  }

  // 开始录音(实时的)
  Future<void> _startRecordingStream() async {
    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _audioRecorder.startStream(config);

      _audioStreamSubscription = stream.listen(
        (audioData) {
          if (_isRealtimeRecording && _apiClient.isTaskStarted) {
            _apiClient.sendAudioData(audioData);
          }
        },

        onError: (error) {
          debugPrint('录音流错误: $error');
          _stopRealtimeRecognition();
        },
      );
    } catch (e) {
      debugPrint('启动录音流失败: $e');
      _stopRealtimeRecognition();
    }
  }

  // 停止录音
  Future<void> _stopRecording() async {
    try {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      await _audioRecorder.stop();
    } catch (e) {
      debugPrint('停止录音失败: $e');
    }
  }

  // 可启用联网搜索的条件
  // 1 模型是阿里百炼、智谱平台(平台自带联网搜索)
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

  // 是否可以发送
  bool _canSend() {
    return _inputText.trim().isNotEmpty || _hasAttachments();
  }

  ///
  /// 发送消息
  ///
  Future<void> _sendMessage(UnifiedChatViewModel viewModel) async {
    unfocusHandle();

    if (viewModel.currentModel == null) {
      ToastUtils.showError("请先选择模型");
      return;
    }

    if (!_canSend() || viewModel.isStreaming) return;

    final text = _inputText.trim();

    // 如果是编辑模式，完成编辑
    if (viewModel.isUserEditingMode) {
      await viewModel.finishEditingUserMessage(
        text,
        isWebSearch: viewModel.isWebSearchEnabled,
      );
      setState(() {
        _inputText = '';
        _textController.clear();
      });
      _clearAllAttachments();
      return;
    }

    // 检查当前模型类型
    // 用户需要手动选择图片生成模型来使用图片生成功能
    if (viewModel.isImageGenerationModel) {
      // 如果是阿里的图生图(图像编辑)，可能必须传入图片
      if (viewModel.currentPlatform?.id == UnifiedPlatformId.aliyun.name &&
          viewModel.currentModel?.type == UnifiedModelType.iti) {
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

    // 语音识别模型：需要选择音频文件进行识别
    if (viewModel.isSpeechRecognitionModel) {
      await _handleSpeechRecognition(viewModel);
      return;
    }

    // 一般的cc模型(支持视觉理解、文档解析等，就可能用得到这些多模态文件)
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
    setState(() {
      _inputText = '';
      _textController.clear();
    });
    _clearAllAttachments();
    // 收起工具栏
    _isToolExpanded = false;
    // unfocusHandle();
  }

  // 处理图片生成
  Future<void> _handleImageGeneration(
    UnifiedChatViewModel viewModel,
    String prompt,
  ) async {
    // 获取当前平台和模型
    final platform = viewModel.currentPlatform;
    final model = viewModel.currentModel;

    // qwen-mt-image 不需要提示词
    if (prompt.isEmpty && model?.modelName.contains("qwen-mt-image") == false) {
      ToastUtils.showError('请输入图片描述');
      return;
    }

    try {
      if (platform == null || model == null) {
        ToastUtils.showError('请先选择平台和模型');
        return;
      }

      // 获取当前对话的图片生成设置 (图片生成高级设置弹窗配置的参数会放在对话的extraParams属性中)
      final conversation = viewModel.currentConversation;
      final Map<String, dynamic> currentSettings =
          conversation?.extraParams?['imageGenerationParams'] ?? {};

      // 先深拷贝一份输入框文本和附件文件，在发送消息之前清空输入框和附件,避免发送按钮等在发送后依旧可见
      String text = _textController.text.trim();
      if (model.modelName.contains("qwen-mt-image") == true) {
        text = "将图片文本翻译为${currentSettings['targetLanguage']}";
      }
      final List<File> images = List.from(_selectedImages);

      // 清空输入框和附件(避免耗时太久输入框等未复原)
      _textController.clear();
      _clearAllAttachments();
      _isToolExpanded = false;

      // 调用专门的图片生成方法
      await viewModel.sendImageGenerationMessage(
        prompt: text,
        images: images,
        settings: currentSettings,
      );
    } catch (e) {
      ToastUtils.showError('图片生成失败: $e');
    }
  }

  // 处理语音合成
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

  // 处理语音识别
  Future<void> _handleSpeechRecognition(UnifiedChatViewModel viewModel) async {
    try {
      // 获取当前对话的语音识别设置
      final conversation = viewModel.currentConversation;
      final Map<String, dynamic> currentSettings =
          conversation?.extraParams?['speechRecognitionParams'] ?? {};

      // 先深拷贝一份输入框文本和音频文件，在发送消息之前清空输入框和附件,避免发送按钮等在发送后依旧可见
      // 录音文件识别不需要输入框文本，只需要选择的单个文件
      final List<File> files = List.from([_selectedAudio]);

      // 清空输入框和附件(避免耗时太久输入框等未复原)
      _textController.clear();
      _clearAllAttachments();
      _isToolExpanded = false;

      if (files.isNotEmpty) {
        // 调用专门的语音识别方法
        await viewModel.sendSpeechRecognitionMessage(
          audioPath: files.first.path,
          settings: currentSettings,
        );
      }
    } catch (e) {
      ToastUtils.showError('语音识别失败: $e');
    }
  }

  ///
  /// 附件选择和清除
  ///
  Future<void> _pickImages() async {
    final images = await ImagePickerUtils.pickMultipleImages();

    if (images.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePickerUtils.takePhotoAndSave();

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await ImagePickerUtils.pickVideo();
    if (video != null) {
      if (!mounted) return;
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _pickAudio(UnifiedChatViewModel viewModel) async {
    File? result = await FilePickerUtils.pickAndSaveFile(
      overwrite: true,
      fileType: CusFileType.custom,
      // 录音文件识别：智谱只支持wav、mp3格式的音频；阿里百炼多一点；硅基流动没有明确限制
      allowedExtensions: viewModel.isSpeechRecognitionModel
          ? ['wav', 'mp3']
          // omni音频格式更多
          : null,
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _selectedAudio = result;
      });
    }
  }

  Future<void> _pickFiles(UnifiedChatViewModel viewModel) async {
    List<File> result = await FilePickerUtils.pickAndSaveMultipleFiles(
      allowMultiple: true,
      fileType: CusFileType.custom,
      overwrite: true,
      // 根据云端解析接口支持来确定，例如智谱的文件解析服务的lite版本支持:
      // pdf,docx,doc,xls,xlsx,ppt,pptx,png,jpg,jpeg,csv,txt,md
      // https://docs.bigmodel.cn/cn/guide/tools/file-parser
      allowedExtensions: ['pdf', 'docx', 'doc', 'xls', 'xlsx', 'ppt', 'pptx'],
    );
    if (result.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _selectedFiles.addAll(result);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        // 监听编辑状态变化
        _handleEditingStateChange(viewModel);

        return Container(
          margin: const EdgeInsets.only(top: 4),
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

                  // 输入区域(如果对话已被归档，则不显示输入区域)
                  if (!viewModel.isConversationArchived)
                    _buildInputArea(viewModel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ///
  /// 构建各部分组件
  ///
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 文本输入区域
            viewModel.isKeyboardInput
                ? _buildTextInputArea(viewModel)
                : // 录音按钮
                  _buildVoiceInputButton(viewModel),

            // 工具按钮区域
            if (_isToolExpanded) _buildToolsArea(viewModel),

            // 底部操作区域
            _buildBottomArea(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputArea(UnifiedChatViewModel viewModel) {
    return Container(
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
                setState(() {
                  _inputText = '';
                  _textController.clear();
                });
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
                hintText: viewModel.isUserEditingMode ? '编辑消息...' : '输入消息...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (text) {
                setState(() {
                  _inputText = text;
                });
              },
              onSubmitted: (text) => _sendMessage(viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputButton(UnifiedChatViewModel viewModel) {
    return GestureDetector(
      onLongPressStart: (details) {
        _initialPanY = details.globalPosition.dy;
        _isDragCancelled = false;
        _startRealtimeRecognition();
      },
      onLongPressMoveUpdate: (details) {
        if (_isRealtimeRecording) {
          final deltaY = _initialPanY - details.globalPosition.dy;
          if (deltaY > _cancelThreshold) {
            if (!_isDragCancelled) {
              setState(() {
                _isDragCancelled = true;
              });
              HapticFeedback.lightImpact();
            }
          } else {
            if (_isDragCancelled) {
              setState(() {
                _isDragCancelled = false;
              });
            }
          }
        }
      },
      onLongPressEnd: (details) {
        if (_isRealtimeRecording) {
          // 延迟一秒钟再实际停止
          Future.delayed(const Duration(seconds: 1), () {
            _stopRealtimeRecognition();
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: _isRealtimeRecording
                ? (_isDragCancelled ? Colors.grey : Colors.red)
                : AppColors.success,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRealtimeRecording ? Icons.mic : Icons.mic_none,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                _isRealtimeRecording
                    ? (_isDragCancelled ? '松开取消' : '松开发送')
                    : '按住说话',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isRealtimeRecording && !_isDragCancelled)
                const SizedBox(width: 4),
              if (_isRealtimeRecording && !_isDragCancelled)
                Text(
                  '上滑取消',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsArea(UnifiedChatViewModel viewModel) {
    final model = viewModel.currentModel;

    bool isPickAudio =
        viewModel.isSpeechRecognitionModel ||
        viewModel.currentModel?.modelName.toLowerCase().contains("omni") ==
            true;

    if (model == null) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Divider(height: 1),
          const SizedBox(height: 8),

          // 第一行工具
          Row(
            children: [
              // 可选择图片(视觉模型、图生图模型)
              if (model.supportsVision ||
                  model.type == UnifiedModelType.iti) ...[
                _buildToolButton(
                  icon: Icons.image_outlined,
                  label: '图片',
                  onPressed: _pickImages,
                ),
                const SizedBox(width: 16),

                _buildToolButton(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  onPressed: _takePhoto,
                ),
                const SizedBox(width: 16),
              ],

              // 可选择视频(阿里云的部分视觉模型)
              if (model.supportsVision) ...[
                _buildToolButton(
                  icon: Icons.videocam_outlined,
                  label: '视频',
                  onPressed: _pickVideo,
                ),
                const SizedBox(width: 16),
              ],

              // 可选择音频文件(语音文件识别和全模态的omni模型)
              if (isPickAudio) ...[
                _buildToolButton(
                  icon: Icons.audio_file_outlined,
                  label: '音频',
                  onPressed: () => _pickAudio(viewModel),
                ),
                const SizedBox(width: 16),
              ],

              // 可选择文件(语音文件识别)
              // 理论上cc模型可支持文档上传，解析文档内容让大模型进一步处理，目前暂无文档上传接口
              // if (model.type == UnifiedModelType.cc)
              if (DateTime.now().year < 2025) ...[
                _buildToolButton(
                  icon: Icons.book,
                  label: '文档',
                  onPressed: () => _pickFiles(viewModel),
                ),
                const SizedBox(width: 16),
              ],
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
            if (viewModel.currentModel != null)
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
          if (viewModel.canShowAttachmentButton)
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

  ///
  /// 显示工具说明对话框
  ///
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

  ///
  /// 显示高级设置对话框
  ///
  void _showAdvancedSettings(UnifiedChatViewModel viewModel) {
    final currentModel = viewModel.currentModel;
    final isImageGenerationModel =
        currentModel?.type == UnifiedModelType.tti ||
        currentModel?.type == UnifiedModelType.iti;
    final isSpeechSynthesisModel = currentModel?.type == UnifiedModelType.tts;
    final isSpeechRecognitionModel = currentModel?.type == UnifiedModelType.asr;

    if (isImageGenerationModel) {
      // 显示图片生成设置对话框
      _showImageGenerationSettings(viewModel);
    } else if (isSpeechSynthesisModel) {
      // 显示语音合成设置对话框
      _showSpeechSynthesisSettings(viewModel);
    } else if (isSpeechRecognitionModel) {
      // 显示语音识别设置对话框
      // 2025-10-13 硅基流动暂时没有语音识别的高级设置
      if (viewModel.currentPlatform?.id ==
          UnifiedPlatformId.siliconCloud.name) {
        ToastUtils.showInfo('硅基流动暂时没有语音识别的高级设置');
      } else {
        _showSpeechRecognitionSettings(viewModel);
      }
    } else {
      // 显示常规聊天设置对话框
      _showChatSettings(viewModel);
    }
  }

  // 显示常规聊天设置对话框
  void _showChatSettings(UnifiedChatViewModel viewModel) {
    // 获取当前对话的设置，使用有效搭档（当前搭档或默认搭档）
    final conversation = viewModel.currentConversation;
    final effectivePartner = viewModel.effectivePartner;

    final Map<String, dynamic> currentSettings =
        conversation?.extraParams?['omniParams'] ?? {};

    showDialog(
      context: context,
      builder: (context) => ChatSettingsDialog(
        viewModel: viewModel,
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
        omniParams: currentSettings,
        selectedPartner: viewModel.currentPartner,
        onSave: (settings) {
          List<String>? modalities = settings['modalities'];
          var omniParams = {
            'modalities': modalities,
            // 如果输出模态中有音频，必须指定一个音色
            if (modalities?.contains('audio') ?? false)
              'audio': settings['audio'],
          };

          viewModel.updateConversationSettings({
            ...settings,
            'partnerId': viewModel.currentPartner?.id,
            'omniParams': omniParams,
          });
        },
      ),
    );
  }

  // 显示图片生成设置对话框
  void _showImageGenerationSettings(UnifiedChatViewModel viewModel) {
    final conversation = viewModel.currentConversation;
    // 这里只取图片生成部分的参数
    final Map<String, dynamic> currentSettings =
        conversation?.extraParams?['imageGenerationParams'] ?? {};

    showDialog(
      context: context,
      builder: (context) => ImageGenerationSettingsDialog(
        currentPlatform: viewModel.currentPlatform,
        currentModel: viewModel.currentModel,
        currentSettings: currentSettings,
        onSave: (settings) {
          // 保存时也使用同样的参数
          viewModel.updateConversationSettings({
            'imageGenerationParams': settings,
          });
        },
      ),
    );
  }

  // 显示语音合成设置对话框
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

  // 显示语音识别设置对话框
  void _showSpeechRecognitionSettings(UnifiedChatViewModel viewModel) {
    final conversation = viewModel.currentConversation;
    // 这里只取语音识别部分的参数
    final Map<String, dynamic> currentSettings =
        conversation?.extraParams?['speechRecognitionParams'] ?? {};

    showDialog(
      context: context,
      builder: (context) => SpeechRecognitionSettingsDialog(
        currentPlatform: viewModel.currentPlatform,
        currentModel: viewModel.currentModel,
        currentSettings: currentSettings,
        onSave: (settings) {
          // 保存时也使用同样的参数
          viewModel.updateConversationSettings({
            'speechRecognitionParams': settings,
          });
        },
      ),
    );
  }
}
