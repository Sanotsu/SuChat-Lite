import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../../../core/entities/cus_llm_model.dart';
import '../../../../../core/theme/style/app_colors.dart';
import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../../../../shared/services/model_manager_service.dart';
import '../../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../../shared/widgets/toast_utils.dart';

/// 录音区域组件
///
// 实时语音识别时：
//  所有语音识别片段都会实时更新到输入框，光标自动移到文本末尾
// 用户手动编辑时：
//   编辑后 1 秒内，如果有语音识别更新，会保持当前光标位置。文本内容仍会更新，但光标不会跳转
//   编辑后超过 1 秒，恢复正常的语音识别行为
// 混合场景：
//   用户可以在语音识别过程中进行编辑
//   编辑时光标位置受保护，不会跳到末尾
//   语音识别内容持续更新，不会丢失后续片段
class RecordingSection extends StatefulWidget {
  final Function(CusLLMSpec?) onModelSelected;
  final Function(String) onTextChanged;
  final Function()? onRealtimeRecordingStart;
  final Function()? onRealtimeRecordingStop;
  final Function(Uint8List)? onAudioData;
  final String currentText;
  final bool isEnabled;

  const RecordingSection({
    super.key,
    required this.onModelSelected,
    required this.onTextChanged,
    this.onRealtimeRecordingStart,
    this.onRealtimeRecordingStop,
    this.onAudioData,
    required this.currentText,
    this.isEnabled = true,
  });

  @override
  State<RecordingSection> createState() => _RecordingSectionState();
}

class _RecordingSectionState extends State<RecordingSection> {
  late TextEditingController _textController;
  bool _isRealtimeRecording = false;
  late AudioRecorder _audioRecorder;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _audioTimer;
  // 标记是否来自语音识别更新
  bool _isUpdatingFromVoice = false;
  // 记录用户最后一次主动编辑的时间
  DateTime? _lastUserEditTime;
  // 用户编辑的保护时间窗口（毫秒）
  static const int _userEditProtectionMs = 1000;

  // 模型列表
  List<CusLLMSpec> modelList = [];
  // 选中的模型
  CusLLMSpec? selectedModel;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentText);
    _audioRecorder = AudioRecorder();

    _loadModels();
  }

  @override
  void didUpdateWidget(RecordingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentText != oldWidget.currentText) {
      _updateTextFromVoice(widget.currentText);
    }
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
      // 恢复光标位置，但要确保不超出文本范围
      final newOffset = currentSelection.baseOffset.clamp(0, text.length);
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: newOffset),
      );
    } else {
      // 正常情况下，将光标移到末尾
      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    }

    _isUpdatingFromVoice = false;
  }

  // 记录用户编辑时间
  void _recordUserEdit() {
    _lastUserEditTime = DateTime.now();
  }

  @override
  void dispose() {
    _stopRecording();
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    final models = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.asr_realtime,
    ]);

    if (!mounted) return;
    setState(() {
      modelList = models;
      selectedModel = models.isNotEmpty ? models.first : null;
      widget.onModelSelected(selectedModel);
    });
  }

  void _startRealtimeRecording() async {
    try {
      // 检查录音权限
      if (await _audioRecorder.hasPermission()) {
        setState(() {
          _isRealtimeRecording = true;
        });

        // 启动实时语音识别
        widget.onRealtimeRecordingStart?.call();

        // 开始录音流
        await _startRecordingStream();
      } else {
        ToastUtils.showError('需要录音权限才能使用语音识别功能');
      }
    } catch (e) {
      ToastUtils.showError('启动录音失败: $e');
    }
  }

  void _stopRealtimeRecording() async {
    await _stopRecording();
    setState(() {
      _isRealtimeRecording = false;
    });
    widget.onRealtimeRecordingStop?.call();
  }

  Future<void> _startRecordingStream() async {
    try {
      // 配置录音参数
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      // 开始录音流
      final stream = await _audioRecorder.startStream(config);

      // 监听音频数据流
      _audioStreamSubscription = stream.listen(
        (audioData) {
          // 发送音频数据到语音识别服务
          widget.onAudioData?.call(audioData);
        },
        onError: (error) {
          debugPrint('录音流错误: $error');
          _stopRealtimeRecording();
        },
      );
    } catch (e) {
      debugPrint('启动录音流失败: $e');
      _stopRealtimeRecording();
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.mic, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '说话或输入文本',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// 模型选择区域
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '模型选择',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildDropdownButton2<CusLLMSpec?>(
                        value: selectedModel,
                        items: modelList,
                        height: 48,
                        hintLabel: "选择模型",
                        itemsEmptyHint: "尚无可选实时语音识别模型",
                        alignment: Alignment.centerLeft,
                        onChanged: !widget.isEnabled || _isRealtimeRecording
                            ? null
                            : (value) {
                                setState(() {
                                  selectedModel = value!;
                                  widget.onModelSelected(selectedModel);
                                });
                              },
                        itemToString: (e) => "${(e as CusLLMSpec).model} ",
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: (selectedModel != null)
                        ? IconButton(
                            onPressed: !widget.isEnabled
                                ? () {}
                                : _isRealtimeRecording
                                ? _stopRealtimeRecording
                                : _startRealtimeRecording,
                            icon: Icon(
                              _isRealtimeRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 36,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _isRealtimeRecording
                                  ? Colors.red
                                  : AppColors.success,
                              padding: const EdgeInsets.all(16),
                            ),
                          )
                        : IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.mic_off, size: 36),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 文本输入区域
            TextField(
              controller: _textController,
              enabled: widget.isEnabled,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '说话或输入要翻译的文本……',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                          widget.onTextChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: (text) {
                // 只有在非语音更新时才触发回调
                if (!_isUpdatingFromVoice) {
                  // 记录用户编辑时间
                  _recordUserEdit();
                  widget.onTextChanged(text);
                }
              },
            ),

            // 提示信息
            if (_textController.text.isEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '💡 提示：可以说一句话或直接输入文本进行翻译',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
