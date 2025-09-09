import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/theme/style/app_colors.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/services/translation_service.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../media_generation/voice/data/repositories/voice_generation_service.dart';
import '../../data/datasources/aliyun_translator_apis.dart';
import '../../data/models/aliyun_asr_realtime_models.dart';
import '../../data/models/translator_supported_languages.dart';
import 'full_translator_page.dart';

/// 快速翻译页面
/// 实时语音识别、翻译、语音合成模型内嵌，用户不可选择但需要导入自己阿里云百炼的AK
class MiniTranslatorPage extends StatefulWidget {
  const MiniTranslatorPage({super.key});

  @override
  State<MiniTranslatorPage> createState() => _MiniTranslatorPageState();
}

class _MiniTranslatorPageState extends State<MiniTranslatorPage> {
  // API客户端
  late AliyunTranslatorApiClient _apiClient;

  // 文本控制器
  late TextEditingController _textController;

  // 状态变量
  String _inputText = '';
  String? _translatedText;
  String? _audioUrl;

  // 语言配置
  LanguageOption _sourceLanguage = SupportedLanguages.languages.first; // 自动
  LanguageOption _targetLanguage = SupportedLanguages.languages[3]; // 英语

  // 语音合成配置
  AliyunVoiceType _selectedVoice =
      VoiceGenerationService.getQwenTTSVoices().first;

  // 加载状态
  bool _isTranslating = false;
  bool _isSynthesizing = false;
  bool _isRealtimeRecording = false;
  Stream<AsrRtResult>? _realtimeStream;
  StreamSubscription<AsrRtResult>? _realtimeSubscription;

  // 录音相关
  late AudioRecorder _audioRecorder;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _audioTimer;
  bool _isUpdatingFromVoice = false;
  DateTime? _lastUserEditTime;
  static const int _userEditProtectionMs = 1000;

  // 错误状态
  bool _hasTranslationError = false;
  String? _translationErrorMessage;
  bool _hasSynthesisError = false;
  String? _synthesisErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApiClient();
    _textController = TextEditingController(text: _inputText);
    _audioRecorder = AudioRecorder();
  }

  void _initializeApiClient() {
    _apiClient = AliyunTranslatorApiClient();
  }

  @override
  void dispose() {
    _stopRecording();
    _realtimeSubscription?.cancel();
    _textController.dispose();
    _audioRecorder.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  // 检查用户是否在保护时间窗口内进行了编辑
  bool _isInUserEditProtection() {
    if (_lastUserEditTime == null) return false;
    final now = DateTime.now();
    final timeDiff = now.difference(_lastUserEditTime!).inMilliseconds;
    return timeDiff < _userEditProtectionMs;
  }

  // 从语音识别更新文本
  void _updateTextFromVoice(String text) {
    if (_isUpdatingFromVoice) return;

    _isUpdatingFromVoice = true;

    // 如果用户正在编辑，保持光标位置
    if (_isInUserEditProtection() && _textController.selection.isValid) {
      final currentSelection = _textController.selection;
      _textController.text = text;
      final newOffset = currentSelection.baseOffset.clamp(0, text.length);
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: newOffset),
      );
    } else {
      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    }

    setState(() {
      _inputText = text;
    });

    _isUpdatingFromVoice = false;
  }

  // 记录用户编辑时间
  void _recordUserEdit() {
    _lastUserEditTime = DateTime.now();
  }

  // 开始实时语音识别
  void _startRealtimeRecognition() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() {
          _isRealtimeRecording = true;
          _inputText = '';
          _textController.clear();
        });

        // 初始化语音识别连接
        // 快速翻译，时是语音识别模型用默认的
        final model = CusLLMSpec(
          ApiPlatform.aliyun,
          "paraformer-realtime-v2",
          LLModelType.asr_realtime,
          cusLlmSpecId: 'aliyun-paraformer-realtime-v2',
        );

        _realtimeStream = await _apiClient.initSpeechRecognition(
          model: model,
          params: AsrRtParameter(sampleRate: 16000, format: 'pcm'),
        );

        _realtimeSubscription = _realtimeStream!.listen(
          (result) {
            if (result.isTaskStarted) {
              ToastUtils.showToast('语音识别已启动，开始说话...');
            } else if (result.isResultGenerated && !result.shouldSkip) {
              if (result.text != null && result.text!.isNotEmpty) {
                _updateTextFromVoice(_inputText + result.text!);
              }
            } else if (result.isTaskFinished) {
              ToastUtils.showToast('语音识别已完成');
              _stopRealtimeRecognition();
            } else if (result.isTaskFailed) {
              ToastUtils.showError('实时识别失败: ${result.errorMessage ?? "未知错误"}');
              _stopRealtimeRecognition();
            }
          },
          onError: (error) {
            ToastUtils.showError('实时识别错误: $error');
            _stopRealtimeRecognition();
          },
        );

        // 开始录音流
        await _startRecordingStream();
      } else {
        ToastUtils.showError('需要录音权限才能使用语音识别功能');
      }
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
      await _stopRecording();
      await _realtimeSubscription?.cancel();
      _realtimeSubscription = null;
      _realtimeStream = null;
      await _apiClient.endSpeechRecognition();

      setState(() {
        _isRealtimeRecording = false;
      });

      ToastUtils.showToast('实时语音识别已停止');
    } catch (e) {
      setState(() {
        _isRealtimeRecording = false;
      });
      ToastUtils.showError('停止实时识别失败: $e');
    }
  }

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

  Future<void> _stopRecording() async {
    try {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      await _audioRecorder.stop();
      _audioTimer?.cancel();
      _audioTimer = null;
    } catch (e) {
      debugPrint('停止录音失败: $e');
    }
  }

  // 处理文本输入变化
  void _onTextChanged(String text) {
    if (!_isUpdatingFromVoice) {
      _recordUserEdit();
      setState(() {
        _inputText = text;
      });
    }
  }

  // 交换语言
  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
  }

  // 执行翻译
  void _translate() async {
    if (_inputText.trim().isEmpty) {
      ToastUtils.showError('请输入要翻译的文本');
      return;
    }

    setState(() {
      _isTranslating = true;
      _hasTranslationError = false;
      _translationErrorMessage = null;
      _translatedText = null;
      _audioUrl = null;
    });

    try {
      // 快速翻译，翻译模型用预设的
      final model = CusLLMSpec(
        ApiPlatform.aliyun,
        "qwen-mt-turbo",
        LLModelType.cc,
        cusLlmSpecId: 'aliyun_qwen_mt_turbo',
      );

      final result = await _apiClient.translateText(
        _inputText.trim(),
        model,
        _targetLanguage.value,
        sourceLang: _sourceLanguage.value,
      );

      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
      ToastUtils.showToast('翻译完成');
    } catch (e) {
      setState(() {
        _hasTranslationError = true;
        _translationErrorMessage = '翻译失败: $e';
        _isTranslating = false;
      });
    }
  }

  // 执行语音合成
  void _synthesizeSpeech() async {
    if (_translatedText == null || _translatedText!.trim().isEmpty) {
      ToastUtils.showError('没有可合成的翻译文本');
      return;
    }

    setState(() {
      _isSynthesizing = true;
      _hasSynthesisError = false;
      _synthesisErrorMessage = null;
      _audioUrl = null;
    });

    try {
      // 快速翻译，语音合成用默认的
      final model = CusLLMSpec(
        ApiPlatform.aliyun,
        "qwen-tts",
        LLModelType.tts,
        cusLlmSpecId: 'aliyun_qwen_tts',
      );
      final result = await _apiClient.synthesizeSpeech(
        _translatedText!.trim(),
        model,
        _selectedVoice,
      );

      setState(() {
        _audioUrl = result;
        _isSynthesizing = false;
      });
      ToastUtils.showToast('语音合成完成');
    } catch (e) {
      setState(() {
        _hasSynthesisError = true;
        _synthesisErrorMessage = '语音合成失败: $e';
        _isSynthesizing = false;
      });
    }
  }

  bool get _isEnabled => !_isTranslating && !_isSynthesizing;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenHelper.isDesktop();
    final padding = isDesktop ? 24.0 : 8.0;
    final sectionSpacing = isDesktop ? 16.0 : 8.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速翻译'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullTranslatorPage(),
                ),
              );
            },
            icon: Icon(Icons.translate),
            tooltip: '自选模型翻译',
          ),
          IconButton(
            onPressed: () {
              _showHelpDialog();
            },
            icon: Icon(Icons.help_outline),
            tooltip: '使用帮助',
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                // 输入区域
                _buildInputSection(),

                // 中间分隔线
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(vertical: sectionSpacing),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey[300]!,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // 结果区域
                _buildResultSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    final isDesktop = ScreenHelper.isDesktop();
    final innerPadding = isDesktop ? 16.0 : 4.0;
    final spacing = isDesktop ? 16.0 : 4.0;
    final textPadding = isDesktop ? 16.0 : 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: Column(
          children: [
            // 语言选择行
            Row(
              children: [
                // 源语言选择
                Expanded(
                  child: buildDropdownButton2<LanguageOption?>(
                    value: _sourceLanguage,
                    items: SupportedLanguages.languages,
                    height: 36,
                    itemMaxHeight: 300,
                    hintLabel: "源语言",
                    alignment: Alignment.center,
                    onChanged: _isEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _sourceLanguage = value;
                              });
                            }
                          }
                        : null,
                    itemToString: (e) => (e as LanguageOption).name,
                  ),
                ),

                // 交换按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    onPressed: _isEnabled ? _swapLanguages : null,
                    icon: const Icon(Icons.swap_horiz),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),

                // 目标语言选择
                Expanded(
                  child: buildDropdownButton2<LanguageOption?>(
                    value: _targetLanguage,
                    items: SupportedLanguages.languages,
                    height: 36,
                    itemMaxHeight: 300,
                    hintLabel: "目标语言",
                    alignment: Alignment.center,
                    onChanged: _isEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() {
                                _targetLanguage = value;
                              });
                            }
                          }
                        : null,
                    itemToString: (e) => (e as LanguageOption).name,
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing),

            // 文本输入区域
            Container(
              height: 0.25.sh,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _textController,
                enabled: _isEnabled,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '输入要翻译的文本...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(textPadding),
                ),
                onChanged: _onTextChanged,
              ),
            ),

            SizedBox(height: spacing),

            // 操作按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 录音按钮
                _buildActionButton(
                  onPressed: _isEnabled
                      ? (_isRealtimeRecording
                            ? _stopRealtimeRecognition
                            : _startRealtimeRecognition)
                      : null,
                  icon: _isRealtimeRecording ? Icons.stop : Icons.mic,
                  label: _isRealtimeRecording ? '停止' : '说话',
                  color: _isRealtimeRecording ? Colors.red : AppColors.success,
                  isLoading: false,
                ),

                // 清空按钮
                _buildActionButton(
                  onPressed: _isEnabled && _inputText.isNotEmpty
                      ? () {
                          _textController.clear();
                          setState(() {
                            _inputText = '';
                            _translatedText = null;
                            _audioUrl = null;
                          });
                        }
                      : null,
                  icon: Icons.clear,
                  label: '清空',
                  color: Colors.grey[600]!,
                  isLoading: false,
                ),

                // 翻译按钮
                _buildActionButton(
                  onPressed: _isEnabled && _inputText.trim().isNotEmpty
                      ? _translate
                      : null,
                  icon: Icons.translate,
                  label: '翻译',
                  color: AppColors.primary,
                  isLoading: _isTranslating,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final isDesktop = ScreenHelper.isDesktop();
    final innerPadding = isDesktop ? 16.0 : 4.0;
    final spacing = isDesktop ? 16.0 : 4.0;
    final resultPadding = isDesktop ? 16.0 : 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: Column(
          children: [
            // 结果显示区域
            Container(
              width: double.infinity,
              height: 0.25.sh,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: EdgeInsets.all(resultPadding),
              child: _buildResultContent(),
            ),

            // 语音合成控制区域
            if (_translatedText != null &&
                _translatedText!.isNotEmpty &&
                (_targetLanguage.value == TargetLanguage.zh ||
                    _targetLanguage.value == TargetLanguage.en)) ...[
              SizedBox(height: spacing),
              _buildSynthesisSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    if (_isTranslating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('翻译中...'),
          ],
        ),
      );
    }

    if (_hasTranslationError && _translationErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _translationErrorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_translatedText != null && _translatedText!.isNotEmpty) {
      return SingleChildScrollView(
        child: SelectableText(
          _translatedText!,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.translate, color: Colors.grey[400], size: 48),
          const SizedBox(height: 16),
          Text('翻译结果将显示在这里', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSynthesisSection() {
    final isDesktop = ScreenHelper.isDesktop();
    final padding = isDesktop ? 12.0 : 4.0;
    final spacing = isDesktop ? 12.0 : 4.0;
    final buttonSpacing = isDesktop ? 12.0 : 4.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          // 音色选择和合成按钮
          Row(
            children: [
              // 音色选择
              Expanded(
                child: buildDropdownButton2<AliyunVoiceType?>(
                  value: _selectedVoice,
                  items: VoiceGenerationService.getQwenTTSVoices(),
                  height: 36,
                  itemMaxHeight: 200,
                  hintLabel: "选择音色",
                  alignment: Alignment.center,
                  onChanged: _isEnabled
                      ? (voice) {
                          if (voice != null) {
                            setState(() {
                              _selectedVoice = voice;
                            });
                          }
                        }
                      : null,
                  itemToString: (e) => (e as AliyunVoiceType).name,
                ),
              ),

              SizedBox(width: buttonSpacing),

              // 合成按钮
              _buildActionButton(
                onPressed:
                    _isEnabled &&
                        _translatedText != null &&
                        _translatedText!.isNotEmpty
                    ? _synthesizeSpeech
                    : null,
                icon: Icons.volume_up,
                label: '语音合成',
                color: AppColors.success,
                isLoading: _isSynthesizing,
              ),
            ],
          ),

          // 音频播放器
          if (_audioUrl != null) ...[
            SizedBox(height: spacing),
            AudioPlayerWidget(audioUrl: _audioUrl!, dense: true),
            SizedBox(height: spacing),
            Text(
              "${_audioUrl?.split('emulated/0').last}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],

          // 错误信息
          if (_hasSynthesisError && _synthesisErrorMessage != null) ...[
            SizedBox(height: spacing * 0.7),
            Text(
              _synthesisErrorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    String? label,
    required Color color,
    required bool isLoading,
  }) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(80, 36),
          padding: EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, size: 22),
            SizedBox(width: 4),
            if (label != null)
              Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('使用说明'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              '1. 使用平台',
              '预设模型使用的是阿里云百炼平台模型，所以需要先在【模型配置】中添加阿里云百炼的ApiKey。',
            ),
            _buildHelpItem(
              '2. 使用模型',
              '实时语音识别:paraformer-realtime-v2\n文本翻译:qwen-mt-turbo\n语音合成:qwen-tts(仅支持简中英文)',
            ),
            _buildHelpItem(
              '3. 模型切换',
              '如果需要切换 paraformer-realtime 、qwen-mt、 qwen-tts系列模型版本，可在模型配置中导入后，点击右侧按钮进入“自选模型翻译”页面。',
            ),
            _buildHelpItem(
              '4. 音频路径',
              'qwen-tts 系列模型合成的语音文件位置:\n${ScreenHelper.isDesktop() ? '/文档' : ''}/SuChatFiles/AI_GEN/voices/translator/',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
