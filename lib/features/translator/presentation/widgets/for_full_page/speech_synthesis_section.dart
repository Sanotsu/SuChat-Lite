import 'package:flutter/material.dart';

import '../../../../../core/entities/cus_llm_model.dart';
import '../../../../../core/theme/style/app_colors.dart';
import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../../../../shared/services/model_manager_service.dart';
import '../../../../../shared/widgets/audio_player_widget.dart';
import '../../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../media_generation/voice/data/repositories/voice_generation_service.dart';

/// 语音合成配置和播放区域组件
class SpeechSynthesisSection extends StatefulWidget {
  final String? translatedText;
  final Function(CusLLMSpec?, AliyunVoiceType) onSynthesize;
  final bool isSynthesizing;
  final String? audioUrl;
  final bool hasError;
  final String? errorMessage;
  final bool isEnabled;

  const SpeechSynthesisSection({
    super.key,
    this.translatedText,
    required this.onSynthesize,
    this.isSynthesizing = false,
    this.audioUrl,
    this.hasError = false,
    this.errorMessage,
    this.isEnabled = true,
  });

  @override
  State<SpeechSynthesisSection> createState() => _SpeechSynthesisSectionState();
}

class _SpeechSynthesisSectionState extends State<SpeechSynthesisSection> {
  AliyunVoiceType _selectedVoice =
      VoiceGenerationService.getQwenTTSVoices().first;

  // 模型列表
  List<CusLLMSpec> modelList = [];
  // 选中的模型
  CusLLMSpec? selectedModel;

  @override
  void initState() {
    super.initState();

    _loadModels();
  }

  Future<void> _loadModels() async {
    final models = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.tts,
    ]);

    // 只使用qwen-tts 模型
    models.removeWhere((e) => !e.model.contains("qwen-tts"));

    if (!mounted) return;
    setState(() {
      modelList = models;
      selectedModel = models.isNotEmpty ? models.first : null;
    });
  }

  void _synthesizeSpeech() {
    if (widget.translatedText == null || widget.translatedText!.isEmpty) {
      return;
    }

    widget.onSynthesize(selectedModel, _selectedVoice);
  }

  bool get _canSynthesize =>
      widget.isEnabled &&
      !widget.isSynthesizing &&
      widget.translatedText != null &&
      widget.translatedText!.isNotEmpty;

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
                Icon(Icons.record_voice_over, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '语音合成(仅支持中英文)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// 模型选择区域
            Text(
              '模型选择',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: buildDropdownButton2<CusLLMSpec?>(
                    value: selectedModel,
                    items: modelList,
                    height: 48,
                    hintLabel: "选择模型",
                    itemsEmptyHint: "尚无可选翻译模型列表",
                    alignment: Alignment.centerLeft,
                    onChanged: !_canSynthesize
                        ? null
                        : (value) {
                            setState(() {
                              selectedModel = value!;
                            });
                          },
                    itemToString: (e) =>
                        "${CP_NAME_MAP[(e as CusLLMSpec).platform]} - ${e.name}",
                  ),
                ),
              ],
            ),

            // 语音选择
            _buildVoiceSelection(),
            const SizedBox(height: 16),

            // 合成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSynthesize ? _synthesizeSpeech : null,
                icon: widget.isSynthesizing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.volume_up),
                label: Text(widget.isSynthesizing ? '合成中...' : '语音合成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 错误信息显示
            if (widget.hasError && widget.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 音频播放区域
            if (widget.audioUrl != null) _buildAudioPlayer(),

            // 提示信息
            if (widget.translatedText == null ||
                widget.translatedText!.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '💡 请先完成翻译后再进行语音合成',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '音色选择',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: buildDropdownButton2<AliyunVoiceType?>(
            value: _selectedVoice,
            items: VoiceGenerationService.getQwenTTSVoices(),
            height: 48,
            itemMaxHeight: 200,
            hintLabel: "选择源语言",
            alignment: Alignment.centerLeft,
            onChanged: widget.isEnabled
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
      ],
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                '语音合成完成',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          if (widget.audioUrl != null)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: AudioPlayerWidget(audioUrl: widget.audioUrl!, dense: true),
            ),
        ],
      ),
    );
  }
}
