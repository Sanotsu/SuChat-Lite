import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/components/toast_utils.dart';
import '../../../common/constants/constants.dart';
import '../../../common/style/app_colors.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../services/voice_recognition_service.dart';

class VoiceRecognitionDetailPage extends StatefulWidget {
  final VoiceRecognitionTaskInfo task;

  const VoiceRecognitionDetailPage({super.key, required this.task});

  @override
  State<VoiceRecognitionDetailPage> createState() =>
      _VoiceRecognitionDetailPageState();
}

class _VoiceRecognitionDetailPageState
    extends State<VoiceRecognitionDetailPage> {
  // 音频波形显示
  bool _isPlaying = false;
  PlayerController? _playerController;

  String? _audioUrl;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 不在initState中初始化，而是在didChangeDependencies中进行，避免在界面未初始化时就修改状态导致报错
    // 防止重复初始化
    if (!_isInitialized) {
      _initAudioPlayer();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    if (widget.task.audioFileUrl == null) return;

    try {
      // 初始化音频播放器
      _audioUrl = widget.task.audioFileUrl;

      // 如果是移动端，初始化波形显示
      if (ScreenHelper.isMobile()) {
        // 释放现有的播放器
        _playerController?.dispose();
        _playerController = PlayerController();
        await _playerController!.preparePlayer(
          path: _audioUrl!,
          noOfSamples: MediaQuery.of(context).size.width ~/ 8,
        );

        // 添加播放完成监听
        _playerController!.onCompletion.listen((_) {
          // 播放完成后播放标志置为false
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        });
      }
      setState(() {});
    } catch (e) {
      debugPrint('初始化音频播放器失败: $e');
    }
  }

  Future<void> _togglePlayback() async {
    if (ScreenHelper.isDesktop() || _playerController == null) return;

    try {
      if (_isPlaying) {
        await _playerController!.pausePlayer();
      } else {
        await _playerController!.startPlayer();
        // 设置播放完成模式为暂停可以重复播放(默认是stop，播放完资源就释放了)
        _playerController!.setFinishMode(finishMode: FinishMode.pause);
      }

      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      debugPrint('播放控制失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('录音识别详情')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 任务信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('任务信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildInfoRow('任务编号', widget.task.taskId),
                    _buildInfoRow('录音语言', widget.task.languageHint ?? 'zh'),
                    _buildInfoRow('识别模型', widget.task.llmSpec?.model ?? '未知'),
                    _buildInfoRow(
                      '创建时间',
                      widget.task.gmtCreate != null
                          ? DateFormat(
                            constDatetimeFormat,
                          ).format(widget.task.gmtCreate!)
                          : '未知',
                    ),
                    if (widget.task.audioDurationMs != null)
                      _buildInfoRow(
                        '音频时长',
                        _formatDuration(widget.task.audioDurationMs!),
                      ),
                    _buildInfoRow(
                      '识别状态',
                      widget.task.taskStatus ?? '未知',
                      valueColor: _getStatusColor(widget.task.taskStatus),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// 音频播放部分
            if (_audioUrl != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '音频文件',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('缓存位置', widget.task.localAudioPath ?? '未知'),
                      _buildInfoRow('云端地址', widget.task.githubAudioUrl ?? '未知'),

                      const SizedBox(height: 16),
                      if (ScreenHelper.isMobile() && _playerController != null)
                        Center(
                          child: AudioFileWaveforms(
                            size: Size(1.sw - 80, 50),
                            playerController: _playerController!,
                            enableSeekGesture: true,
                            waveformType: WaveformType.fitWidth,
                            playerWaveStyle: PlayerWaveStyle(
                              fixedWaveColor: Colors.grey[400]!,
                              liveWaveColor: AppColors.primary,
                              spacing: 6,
                              showBottom: false,
                              showSeekLine: true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: _togglePlayback,
                            color: AppColors.primary,
                            iconSize: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _audioUrl!.split('/').last,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            /// 识别结果部分 - 整体文本
            if (widget.task.recognizedText != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '识别结果',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '共 ${VoiceRecognitionService.cleanText(widget.task.recognizedText!).length} 字',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: VoiceRecognitionService.cleanText(
                                    widget.task.recognizedText!,
                                  ),
                                ),
                              );
                              ToastUtils.showToast('已复制到剪贴板');
                            },
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ConstrainedBox(
                          // 最大高度200，超过则滚动
                          constraints: BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              VoiceRecognitionService.cleanText(
                                widget.task.recognizedText!,
                              ),
                              textAlign: TextAlign.justify, // 双端对齐
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      ),

                      Divider(),
                      // 2025-05-07 除了senseVoice 其他模型好像原始和处理后的没什么区别，可以只显示一个
                      // Text(
                      //   '原始识别结果',
                      //   style: Theme.of(context).textTheme.titleMedium,
                      // ),
                      // Container(
                      //   width: double.infinity,
                      //   padding: const EdgeInsets.all(8),
                      //   child: ConstrainedBox(
                      //     constraints: BoxConstraints(maxHeight: 200),
                      //     child: SingleChildScrollView(
                      //       child: Text(widget.task.recognizedText!),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            /// 分段识别结果 - 时间戳显示
            if (widget.task.sentences != null &&
                widget.task.sentences!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '分段识别结果',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildSentencesTimeline(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 构建分段识别结果时间轴
  Widget _buildSentencesTimeline() {
    final sentences = widget.task.sentences!;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sentences.length,
      itemBuilder: (context, index) {
        final sentence = sentences[index];
        final text = sentence.text;
        final speakerId = sentence.speakerId;
        final startTime = _formatTime(sentence.beginTime / 1000);
        final endTime = _formatTime(sentence.endTime / 1000);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间戳
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      startTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      '至',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      endTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // 文本内容
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (speakerId != null)
                        RichText(
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "说话人",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                              ),
                              TextSpan(
                                text: " ${speakerId + 1}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Text(
                      //   '说话人 $speakerId',
                      //   style: const TextStyle(fontSize: 10),
                      // ),
                      SelectableText(text),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 格式化时间（毫秒转为 mm:ss 格式）
  String _formatTime(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final remainingSeconds = (duration.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$remainingSeconds';
  }

  // 格式化持续时间（毫秒转为更友好的格式）
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'SUCCEEDED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'RUNNING':
      case 'PENDING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
