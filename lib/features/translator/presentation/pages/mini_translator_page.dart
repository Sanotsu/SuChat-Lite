import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/theme/style/app_colors.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/services/translation_service.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../unified_chat/data/database/translation_history_dao.dart';
import '../../../unified_chat/data/database/unified_chat_dao.dart';
import '../../../unified_chat/data/models/speech_recognition_request.dart';
import '../../../unified_chat/data/models/speech_synthesis_request.dart';
import '../../../unified_chat/data/models/unified_model_spec.dart';
import '../../../unified_chat/data/models/unified_platform_spec.dart';
import '../../../unified_chat/data/services/speech_recognition_service.dart';
import '../../../unified_chat/data/services/speech_synthesis_service.dart';
import '../../../unified_chat/data/services/unified_secure_storage.dart';
import '../../data/models/translator_supported_languages.dart';
import 'translation_history_page.dart';

/// 翻译模型条目(统一配置的模型+所属平台)
typedef _ModelEntry = ({UnifiedModelSpec model, UnifiedPlatformSpec platform});

/// 快速翻译页面
/// 2026-09-03 改造：
/// - 语音识别/翻译/语音合成模型均可从平台管理配置的统一模型库中选择
/// - 语音识别改为录音后同步识别(自建平台可用，一般限制25MB内)
/// - 翻译使用对话模型+翻译系统提示词(qwen-mt系列自动走translation_options)
/// - 语音合成固定默认音色，不再提供音色选择
/// - 新增翻译历史(存unified聊天库translation_history表，随DB备份链备份)
class MiniTranslatorPage extends StatefulWidget {
  const MiniTranslatorPage({super.key});

  @override
  State<MiniTranslatorPage> createState() => _MiniTranslatorPageState();
}

class _MiniTranslatorPageState extends State<MiniTranslatorPage> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final TranslationHistoryDao _historyDao = TranslationHistoryDao();
  final SpeechSynthesisService _ttsService = SpeechSynthesisService();

  // 文本控制器
  late TextEditingController _textController;

  // 状态变量
  String _inputText = '';
  String? _translatedText;
  String? _audioUrl;

  // 语言配置
  LanguageOption _sourceLanguage = SupportedLanguages.languages.first; // 自动
  LanguageOption _targetLanguage = SupportedLanguages.languages[3]; // 英语

  // 统一配置的模型条目(平台管理中配置的模型，含用户自建平台)
  final List<_ModelEntry> _asrEntries = [];
  final List<_ModelEntry> _ccEntries = [];
  final List<_ModelEntry> _ttsEntries = [];
  _ModelEntry? _selectedAsr;
  _ModelEntry? _selectedCc;
  _ModelEntry? _selectedTts;
  int? _lastHistoryId;
  bool _isLoadingModels = true;

  // 录音相关
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _recordingPath;
  bool _isRecognizing = false;

  // 加载状态
  bool _isTranslating = false;
  bool _isSynthesizing = false;

  // 错误状态
  bool _hasTranslationError = false;
  String? _translationErrorMessage;
  bool _hasSynthesisError = false;
  String? _synthesisErrorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _inputText);
    _audioRecorder = AudioRecorder();
    _loadModels();
  }

  @override
  void dispose() {
    _stopRecording(cancelOnly: true);
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  /// 加载平台管理配置的模型(统一模型库，按类型分桶)
  Future<void> _loadModels() async {
    try {
      final models = await _chatDao.getModelSpecs();
      final platforms = await _chatDao.getPlatformSpecs();
      final platformMap = {for (final p in platforms) p.id: p};

      final asr = <_ModelEntry>[];
      final cc = <_ModelEntry>[];
      final tts = <_ModelEntry>[];
      for (final m in models) {
        if (!m.isActive) continue;
        final p = platformMap[m.platformId];
        if (p == null || !p.isActive) continue;
        final entry = (model: m, platform: p);
        final type = m.modelType;
        if (type == UnifiedModelType.asr.name) {
          asr.add(entry);
        } else if (type == UnifiedModelType.cc.name) {
          cc.add(entry);
        } else if (type == UnifiedModelType.tts.name) {
          tts.add(entry);
        }
      }

      if (!mounted) return;
      setState(() {
        _asrEntries
          ..clear()
          ..addAll(asr);
        _ccEntries
          ..clear()
          ..addAll(cc);
        _ttsEntries
          ..clear()
          ..addAll(tts);
        // 默认选中第一个可用模型
        _selectedAsr = asr.isEmpty ? null : asr.first;
        _selectedCc = cc.isEmpty ? null : cc.first;
        _selectedTts = tts.isEmpty ? null : tts.first;
        _isLoadingModels = false;
      });
    } catch (e) {
      debugPrint('加载平台管理配置的模型失败: $e');
      if (mounted) {
        setState(() => _isLoadingModels = false);
      }
    }
  }

  /// 将统一配置的对话模型桥接为TranslationService使用的CusLLMSpec
  /// (baseUrl为完整chat端点，apiKey从统一安全存储读取)
  Future<CusLLMSpec?> _buildTranslationSpec(_ModelEntry? entry) async {
    if (entry == null) return null;
    final apiKey = await UnifiedSecureStorage.getApiKey(entry.platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('平台[${entry.platform.displayName}]未配置API Key');
    }
    return CusLLMSpec(
      // platform仅为枚举占位，实际地址与密钥由baseUrl/apiKey提供
      ApiPlatform.aliyun,
      entry.model.modelName,
      LLModelType.cc,
      name: entry.model.displayName,
      baseUrl: entry.platform.getChatCompletionsUrl(),
      apiKey: apiKey,
      cusLlmSpecId: 'unified_${entry.platform.id}_${entry.model.id}',
    );
  }

  // ============ 录音与同步识别 ============

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _stopRecording();
      if (path != null && path.isNotEmpty) {
        await _recognizeAudio(path);
      }
      return;
    }

    try {
      if (!await _audioRecorder.hasPermission()) {
        ToastUtils.showError('需要录音权限才能使用语音输入');
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/translator_rec_$timestamp.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
      ToastUtils.showToast('开始录音，再次点击结束');
    } catch (e) {
      ToastUtils.showError('启动录音失败: $e');
    }
  }

  /// 停止录音并返回文件路径(cancelOnly为true时仅停止不关心结果)
  Future<String?> _stopRecording({bool cancelOnly = false}) async {
    try {
      if (!await _audioRecorder.isRecording()) {
        if (mounted) {
          setState(() => _isRecording = false);
        }
        return null;
      }
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() => _isRecording = false);
      }
      if (cancelOnly && _recordingPath != null) {
        final f = File(_recordingPath!);
        if (f.existsSync()) f.deleteSync();
      }
      return path;
    } catch (e) {
      debugPrint('停止录音失败: $e');
      if (mounted) {
        setState(() => _isRecording = false);
      }
      return null;
    }
  }

  /// 使用选中的语音识别模型同步识别录音文件
  Future<void> _recognizeAudio(String audioPath) async {
    final entry = _selectedAsr;
    if (entry == null) {
      ToastUtils.showError('请先选择语音识别模型');
      return;
    }

    setState(() => _isRecognizing = true);
    try {
      final apiKey = await UnifiedSecureStorage.getApiKey(entry.platform.id);
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('平台[${entry.platform.displayName}]未配置API Key');
      }

      final response = await SpeechRecognitionService.recognizeSpeech(
        platform: entry.platform,
        request: SpeechRecognitionRequest(
          model: entry.model.modelName,
          audioPath: audioPath,
        ),
        apiKey: apiKey,
      );

      final text = response.text;
      if (text.isEmpty) {
        ToastUtils.showError('未识别到内容');
        return;
      }

      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
      setState(() => _inputText = text);
    } catch (e) {
      ToastUtils.showError('语音识别失败: $e');
    } finally {
      // 清理临时录音文件
      final f = File(audioPath);
      if (f.existsSync()) f.deleteSync();
      if (mounted) {
        setState(() {
          _isRecognizing = false;
          _recordingPath = null;
        });
      }
    }
  }

  // ============ 翻译 ============

  // 交换语言
  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
  }

  // 处理文本输入变化
  void _onTextChanged(String text) {
    setState(() {
      _inputText = text;
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
      CusLLMSpec? spec;
      if (_selectedCc != null) {
        spec = await _buildTranslationSpec(_selectedCc);
      }

      final result = await TranslationService.translate(
        _inputText.trim(),
        _targetLanguage.value,
        sourceLang: _sourceLanguage.value,
        model: spec,
      );

      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });

      // 保存翻译历史(记录id，语音合成成功后回写音频路径)
      try {
        _lastHistoryId = await _historyDao.insert(
          TranslationHistoryEntry(
            createdAt: DateTime.now(),
            sourceLang: _sourceLanguage.name,
            targetLang: _targetLanguage.name,
            sourceText: _inputText.trim(),
            translatedText: result,
            modelName:
                _selectedCc?.model.displayName ??
                _selectedCc?.model.modelName ??
                '默认模型',
            platformName: _selectedCc?.platform.displayName,
          ),
        );
      } catch (e) {
        debugPrint('保存翻译历史失败: $e');
      }

      ToastUtils.showToast('翻译完成');
    } catch (e) {
      setState(() {
        _hasTranslationError = true;
        _translationErrorMessage = '翻译失败: $e';
        _isTranslating = false;
      });
    }
  }

  // ============ 语音合成 ============

  // 执行语音合成(固定默认音色)
  void _synthesizeSpeech() async {
    if (_translatedText == null || _translatedText!.trim().isEmpty) {
      ToastUtils.showError('没有可合成的翻译文本');
      return;
    }
    final entry = _selectedTts;
    if (entry == null) {
      ToastUtils.showError('请先选择语音合成模型');
      return;
    }

    setState(() {
      _isSynthesizing = true;
      _hasSynthesisError = false;
      _synthesisErrorMessage = null;
      _audioUrl = null;
    });

    try {
      final response = await _ttsService.synthesizeSpeech(
        platform: entry.platform,
        model: entry.model,
        request: SpeechSynthesisRequest(
          model: entry.model.modelName,
          input: _translatedText!.trim(),
          // 阿里qwen-tts需要显式音色，使用其默认音色；其他平台走服务端默认
          voice: entry.platform.id == 'aliyun' ? 'Cherry' : null,
          responseFormat: entry.platform.id == 'aliyun' ? null : 'mp3',
        ),
      );

      setState(() {
        _audioUrl = response.audioUrl;
        _isSynthesizing = false;
      });

      // 回写音频路径到翻译历史
      if (_lastHistoryId != null && response.audioUrl != null) {
        try {
          await _historyDao.updateAudioPath(
            _lastHistoryId!,
            response.audioUrl!,
          );
        } catch (e) {
          debugPrint('回写翻译历史音频路径失败: $e');
        }
      }

      ToastUtils.showToast('语音合成完成');
    } catch (e) {
      setState(() {
        _hasSynthesisError = true;
        _synthesisErrorMessage = '语音合成失败: $e';
        _isSynthesizing = false;
      });
    }
  }

  bool get _isEnabled => !_isTranslating && !_isSynthesizing && !_isRecognizing;

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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TranslationHistoryPage(),
                ),
              );
            },
            icon: Icon(Icons.history),
            tooltip: '翻译历史',
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

  /// 模型选择行(标题+下拉)
  Widget _buildModelRow({
    required String title,
    required List<_ModelEntry> entries,
    required _ModelEntry? value,
    required String hintLabel,
    required ValueChanged<_ModelEntry?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64.w,
          child: Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Text(
                  '平台管理中暂无可用模型',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                )
              : buildDropdownButton2<_ModelEntry?>(
                  value: value,
                  items: entries,
                  height: 34,
                  itemMaxHeight: 300,
                  hintLabel: hintLabel,
                  alignment: Alignment.centerLeft,
                  onChanged: _isEnabled ? onChanged : null,
                  itemToString: (e) =>
                      '${(e as _ModelEntry).platform.displayName} / ${(e).model.displayName}',
                ),
        ),
      ],
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

            // 模型选择区(语音识别/翻译/语音合成，来自平台管理统一配置)
            if (_isLoadingModels)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Column(
                children: [
                  _buildModelRow(
                    title: '识别模型',
                    entries: _asrEntries,
                    value: _selectedAsr,
                    hintLabel: '语音识别模型',
                    onChanged: (v) => setState(() => _selectedAsr = v),
                  ),
                  SizedBox(height: spacing * 0.6),
                  _buildModelRow(
                    title: '翻译模型',
                    entries: _ccEntries,
                    value: _selectedCc,
                    hintLabel: '翻译模型(不选用内置默认)',
                    onChanged: (v) => setState(() => _selectedCc = v),
                  ),
                  SizedBox(height: spacing * 0.6),
                  _buildModelRow(
                    title: '合成模型',
                    entries: _ttsEntries,
                    value: _selectedTts,
                    hintLabel: '语音合成模型',
                    onChanged: (v) => setState(() => _selectedTts = v),
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
                // 录音按钮(录完自动识别)
                _buildActionButton(
                  onPressed: _isEnabled || _isRecording
                      ? _toggleRecording
                      : null,
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  label: _isRecording ? '停止' : '说话',
                  color: _isRecording ? Colors.red : AppColors.success,
                  isLoading: _isRecognizing,
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
            if (_translatedText != null && _translatedText!.isNotEmpty) ...[
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

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          // 合成按钮行(音色固定默认，不再提供选择)
          Row(
            children: [
              if (_selectedTts != null)
                Expanded(
                  child: Text(
                    '${_selectedTts!.platform.displayName} / ${_selectedTts!.model.displayName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    '平台管理中暂无语音合成模型',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              _buildActionButton(
                onPressed:
                    _isEnabled &&
                        _selectedTts != null &&
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
              '1. 模型配置',
              '三个模型(识别/翻译/合成)均来自【平台管理】中配置的模型，自建平台也可使用；请先在对应平台配置API Key。',
            ),
            _buildHelpItem(
              '2. 语音输入',
              '点击"说话"录音，再次点击结束并自动识别(同步模式，录音一般不超过25MB/数分钟)。',
            ),
            _buildHelpItem(
              '3. 翻译模型',
              '使用所选对话模型+翻译提示词完成翻译；qwen-mt系列自动使用其专用翻译参数。不选择时使用内置默认模型。',
            ),
            _buildHelpItem('4. 翻译历史', '翻译完成后自动保存历史，点击右上角历史按钮查看、复制或删除。'),
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
