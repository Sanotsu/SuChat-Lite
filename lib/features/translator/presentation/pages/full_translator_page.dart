import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/theme/style/app_colors.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/services/translation_service.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../media_generation/voice/data/repositories/voice_generation_service.dart';
import '../../data/datasources/aliyun_translator_apis.dart';
import '../../data/models/aliyun_asr_realtime_models.dart';
import '../../data/models/translator_supported_languages.dart';
import '../widgets/for_full_page/recording_section.dart';
import '../widgets/for_full_page/translation_config_section.dart';
import '../widgets/for_full_page/translation_result_section.dart';
import '../widgets/for_full_page/speech_synthesis_section.dart';

/// 翻译专家主页面
/// 语音识别 - 翻译文本 - 翻译结果语音合成，可自选导入的且支持的模型
class FullTranslatorPage extends StatefulWidget {
  const FullTranslatorPage({super.key});

  @override
  State<FullTranslatorPage> createState() => _FullTranslatorPageState();
}

class _FullTranslatorPageState extends State<FullTranslatorPage> {
  // API客户端
  late AliyunTranslatorApiClient _apiClient;

  // 状态变量
  String _inputText = '';
  String? _translatedText;
  String? _audioUrl;

  // 语言配置
  LanguageOption _sourceLanguage = SupportedLanguages.languages.first; // 自动
  LanguageOption _targetLanguage = SupportedLanguages.languages[3]; // 英语

  // 加载状态
  bool _isTranslating = false;
  bool _isSynthesizing = false;
  bool _isRealtimeRecognizing = false;
  Stream<AsrRtResult>? _realtimeStream;
  StreamSubscription<AsrRtResult>? _realtimeSubscription;
  bool _hasTranslationError = false;
  String? _translationErrorMessage;
  bool _hasSynthesisError = false;
  String? _synthesisErrorMessage;

  // 被选中的实时语音识别模型
  CusLLMSpec? _selectedAsrModel;

  @override
  void initState() {
    super.initState();
    _initializeApiClient();
  }

  void _initializeApiClient() {
    _apiClient = AliyunTranslatorApiClient();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  // 开始实时语音识别
  void _startRealtimeRecognition() async {
    if (_selectedAsrModel == null) return;

    try {
      setState(() {
        _isRealtimeRecognizing = true;
        _inputText = ''; // 清空之前的文本
      });

      // 初始化语音识别连接
      _realtimeStream = await _apiClient.initSpeechRecognition(
        model: _selectedAsrModel!,
        params: AsrRtParameter(
          sampleRate: 16000,
          format: 'pcm',
          // languageHints: ['zh', 'en'], // 支持中英文
        ),
      );

      _realtimeSubscription = _realtimeStream!.listen(
        (result) {
          if (result.isTaskStarted) {
            ToastUtils.showToast('语音识别已启动，开始说话...');
          } else if (result.isResultGenerated && !result.shouldSkip) {
            if (result.text != null && result.text!.isNotEmpty) {
              setState(() {
                // 实时语音识别结果种跳过了中间结果，返回的是整句的句子，但可能是多个句子，所以累加
                _inputText += result.text!;
              });
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
    } catch (e) {
      setState(() {
        _isRealtimeRecognizing = false;
      });
      ToastUtils.showError('启动实时识别失败: $e');
    }
  }

  // 停止实时语音识别
  void _stopRealtimeRecognition() async {
    if (!_isRealtimeRecognizing) return;

    try {
      await _realtimeSubscription?.cancel();
      _realtimeSubscription = null;
      _realtimeStream = null;

      await _apiClient.endSpeechRecognition();

      setState(() {
        _isRealtimeRecognizing = false;
      });

      ToastUtils.showToast('实时语音识别已停止');
    } catch (e) {
      setState(() {
        _isRealtimeRecognizing = false;
      });
      ToastUtils.showError('停止实时识别失败: $e');
    }
  }

  // 处理音频数据
  void _onAudioData(Uint8List audioData) {
    if (_isRealtimeRecognizing && _apiClient.isTaskStarted) {
      _apiClient.sendAudioData(audioData);
    }
  }

  // 处理文本输入变化
  void _onTextChanged(String text) {
    setState(() {
      _inputText = text;
    });
  }

  // 处理源语言变化
  void _onSourceLanguageChanged(LanguageOption? language) {
    if (language != null) {
      setState(() {
        _sourceLanguage = language;
      });
    }
  }

  // 处理目标语言变化
  void _onTargetLanguageChanged(LanguageOption? language) {
    if (language != null) {
      setState(() {
        _targetLanguage = language;
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
  void _translate(CusLLMSpec? model) async {
    if (_inputText.trim().isEmpty || model == null) {
      ToastUtils.showError('请输入要翻译的文本');
      return;
    }

    setState(() {
      _isTranslating = true;
      _hasTranslationError = false;
      _translationErrorMessage = null;
      _translatedText = null;
      _audioUrl = null; // 清除之前的语音
    });

    try {
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
  void _synthesizeSpeech(CusLLMSpec? model, AliyunVoiceType voiceType) async {
    if (model == null) {
      ToastUtils.showError('没有语音合成模型');
      return;
    }

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
      // 翻译专家页面，必须要有语言合成模型
      final result = await _apiClient.synthesizeSpeech(
        _translatedText!.trim(),
        model,
        voiceType,
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenHelper.isDesktop();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.translate, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('翻译专家'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              _showHelpDialog();
            },
            icon: Icon(Icons.help_outline),
            tooltip: '使用帮助',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 8),
          child: Column(
            children: [
              // 录音和文本输入区域
              RecordingSection(
                onModelSelected: (model) {
                  setState(() {
                    _selectedAsrModel = model;
                  });
                },
                onTextChanged: _onTextChanged,
                onRealtimeRecordingStart: _startRealtimeRecognition,
                onRealtimeRecordingStop: _stopRealtimeRecognition,
                onAudioData: _onAudioData,
                currentText: _inputText,
                isEnabled: !_isTranslating && !_isSynthesizing,
              ),

              const SizedBox(height: 16),

              // 翻译配置区域
              if (_inputText.trim().isNotEmpty)
                TranslationConfigSection(
                  sourceLanguage: _sourceLanguage,
                  targetLanguage: _targetLanguage,
                  onSourceLanguageChanged: _onSourceLanguageChanged,
                  onTargetLanguageChanged: _onTargetLanguageChanged,
                  onSwapLanguages: _swapLanguages,
                  onTranslate: _translate,
                  isTranslating: _isTranslating,
                  isEnabled: !_isTranslating && _inputText.trim().isNotEmpty,
                ),

              const SizedBox(height: 16),

              // 翻译结果区域
              if (_translatedText != null)
                TranslationResultSection(
                  translatedText: _translatedText,
                  hasError: _hasTranslationError,
                  errorMessage: _translationErrorMessage,
                  isLoading: _isTranslating,
                ),

              const SizedBox(height: 16),

              // 语音合成区域
              // 2025-08-22 qwen-tts语音合成只支持中英文，所以只有翻译的目标语音是中英文时才显示
              // 虽然 Sambert CosyVoice 部分音色支持部分其他语言，但目前和单独的语音合成一样都没有合理规划好，所以暂时不显示
              if (_translatedText != null &&
                  _translatedText!.isNotEmpty &&
                  (_targetLanguage.value == TargetLanguage.zh ||
                      _targetLanguage.value == TargetLanguage.en))
                SpeechSynthesisSection(
                  translatedText: _translatedText,
                  onSynthesize: _synthesizeSpeech,
                  isSynthesizing: _isSynthesizing,
                  audioUrl: _audioUrl,
                  hasError: _hasSynthesisError,
                  errorMessage: _synthesisErrorMessage,
                  isEnabled:
                      !_isSynthesizing &&
                      _translatedText != null &&
                      _translatedText!.isNotEmpty,
                ),

              // 底部间距
              const SizedBox(height: 16),
            ],
          ),
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
              '1. 平台密钥',
              '本功能需要使用阿里云百炼平台的相关模型，所以需要在【模型配置】页面先导入该平台ApiKey',
            ),
            _buildHelpItem(
              '2. 实时语音识别',
              '需要自行导入类型为\nLLModelType.asr_realtime 的 \nparaformer-realtime 系列模型',
            ),
            _buildHelpItem(
              '3. 翻译模型',
              '需要自行导入类型为\nLLModelType.cc 的 \nqwen-mt 系列(或其他文本对话)模型',
            ),
            _buildHelpItem(
              '4. 语音合成',
              '需要自行导入类型为\nLLModelType.tts 的 \nqwen-tts 系列模型(仅支持中英文合成)',
            ),

            // const SizedBox(height: 12),
            // Container(
            //   padding: const EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     color: Colors.blue[50],
            //     borderRadius: BorderRadius.circular(6),
            //   ),
            //   child: Text(
            //     '💡 支持${SupportedLanguages.languages.length}种语言互译，包括中文、英语、日语、韩语等主流语言。',
            //     style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            //   ),
            // ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
