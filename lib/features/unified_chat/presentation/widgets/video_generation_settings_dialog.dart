import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';

/// 视频生成高级设置对话框
/// 2026-09-02 媒体生成并入聊天新增
/// 分辨率/时长等参数直接影响生成费用(各平台普遍按 分辨率×秒数 计费)，
/// 平台默认多为1080P最贵档，这里默认720P并允许用户按需调整；
/// 参数取值域按平台/模型动态适配(阿里三代协议、智谱、火山等)
class VideoGenerationSettingsDialog extends StatefulWidget {
  final UnifiedPlatformSpec? currentPlatform;
  final UnifiedModelSpec? currentModel;
  final Map<String, dynamic> currentSettings;
  final Function(Map<String, dynamic>) onSave;

  const VideoGenerationSettingsDialog({
    super.key,
    this.currentPlatform,
    this.currentModel,
    this.currentSettings = const {},
    required this.onSave,
  });

  @override
  State<VideoGenerationSettingsDialog> createState() =>
      _VideoGenerationSettingsDialogState();
}

class _VideoGenerationSettingsDialogState
    extends State<VideoGenerationSettingsDialog> {
  late String _resolution;
  late String _ratio;
  late int _duration;
  late bool _watermark;
  late bool _audio;
  late TextEditingController _seedController;

  bool get _isAliyun => widget.currentPlatform?.id == 'aliyun';

  bool get _isZhipu => widget.currentPlatform?.id == 'zhipu';

  String get _modelName => widget.currentModel?.modelName ?? '';

  /// 阿里百炼万相2.7仅支持720P/1080P，其余(2.6/HH/3.0)支持480P/720P/1080P
  List<String> get _resolutionOptions {
    if (_isAliyun &&
        (_modelName.startsWith('wan2.7') || _modelName.startsWith('wan2.6'))) {
      return ['720P', '1080P'];
    }
    if (_isAliyun || _isZhipu) {
      return ['480P', '720P', '1080P'];
    }
    // 硅基流动按图片比例自适应，火山无统一分辨率参数(由prompt/模型决定)
    return ['720P'];
  }

  /// 万相3.0支持adaptive自适应比例；
  /// HappyHorse图生视频不支持ratio(宽高比自动跟随首帧)，仅返回占位单值隐藏该选项
  List<String> get _ratioOptions {
    final isHappyHorse = _isAliyun && _modelName.startsWith('happyhorse');
    if (isHappyHorse && widget.currentModel?.supportsImageInput == true) {
      return const ['跟随首帧'];
    }
    if (isHappyHorse) {
      return [
        '16:9',
        '9:16',
        '1:1',
        '4:3',
        '3:4',
        '4:5',
        '5:4',
        '9:21',
        '21:9',
      ];
    }
    if (_isAliyun && _modelName.startsWith('wan3.')) {
      return ['adaptive', '16:9', '9:16', '1:1', '4:3', '3:4'];
    }
    if (_isAliyun) {
      return ['16:9', '9:16', '1:1', '4:3', '3:4'];
    }
    return ['16:9', '9:16', '1:1'];
  }

  int get _maxDuration {
    if (_isAliyun && _modelName.startsWith('wan3.')) return 30;
    if (_isAliyun) return 15;
    return 15;
  }

  /// 各模型时长下限：wan3.0为[2,30]，HappyHorse为[3,15]
  int get _minDuration {
    if (_isAliyun && _modelName.startsWith('wan3.')) return 2;
    if (_isAliyun && _modelName.startsWith('happyhorse')) return 3;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _resolution = widget.currentSettings['resolution'] as String? ?? '720P';
    _ratio = widget.currentSettings['ratio'] as String? ?? '16:9';
    _duration = (widget.currentSettings['duration'] as num?)?.toInt() ?? 5;
    _watermark = widget.currentSettings['watermark'] as bool? ?? false;
    _audio = widget.currentSettings['audio'] as bool? ?? true;
    _seedController = TextEditingController(
      text: widget.currentSettings['seed']?.toString() ?? '',
    );

    // 存量值不在当前模型取值域时回退默认
    if (!_resolutionOptions.contains(_resolution)) {
      _resolution = _resolutionOptions.first;
    }
    if (!_ratioOptions.contains(_ratio)) {
      _ratio = _ratioOptions.first;
    }
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _save() {
    final settings = <String, dynamic>{
      'resolution': _resolution,
      'ratio': _ratio,
      'duration': _duration,
      'watermark': _watermark,
      'audio': _audio,
      if (_seedController.text.trim().isNotEmpty)
        'seed': int.tryParse(_seedController.text.trim()),
    };

    widget.onSave(settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('视频生成设置'),
      content: SizedBox(
        width: ScreenHelper.isDesktop() ? 460 : double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '分辨率与时长直接影响生成费用(按分辨率×秒计费)，未配置时默认720P',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 分辨率
              _buildLabel('分辨率'),
              Wrap(
                spacing: 8,
                children: _resolutionOptions
                    .map(
                      (r) => ChoiceChip(
                        label: Text(r),
                        selected: _resolution == r,
                        onSelected: (_) => setState(() => _resolution = r),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // 宽高比
              if (_ratioOptions.length > 1) ...[
                _buildLabel('宽高比'),
                Wrap(
                  spacing: 8,
                  children: _ratioOptions
                      .map(
                        (r) => ChoiceChip(
                          label: Text(r),
                          selected: _ratio == r,
                          onSelected: (_) => setState(() => _ratio = r),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // 时长
              _buildLabel('时长(秒)：$_duration'),
              Slider(
                value: _duration.toDouble().clamp(
                  _minDuration.toDouble(),
                  _maxDuration.toDouble(),
                ),
                min: _minDuration.toDouble(),
                max: _maxDuration.toDouble(),
                divisions: _maxDuration - _minDuration,
                label: '$_duration',
                onChanged: (v) => setState(() => _duration = v.round()),
              ),
              const SizedBox(height: 8),

              // 开关们
              SwitchListTile(
                title: const Text('添加水印'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _watermark,
                onChanged: (v) => setState(() => _watermark = v),
              ),
              // 万相3.0/PixVerse等支持输出音频(万相3.0开关同价)
              if (_isAliyun)
                SwitchListTile(
                  title: const Text('生成音频'),
                  subtitle: const Text(
                    '部分模型支持音画同出',
                    style: TextStyle(fontSize: 12),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _audio,
                  onChanged: (v) => setState(() => _audio = v),
                ),
              const SizedBox(height: 8),

              // 种子
              _buildLabel('随机种子(可选，固定可复现)'),
              TextField(
                controller: _seedController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '留空随机',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
