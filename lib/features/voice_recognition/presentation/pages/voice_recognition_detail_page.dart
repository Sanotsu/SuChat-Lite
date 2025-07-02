import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../core/theme/style/app_colors.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/audio_operation_widgets.dart';
import '../../data/repositories/voice_recognition_service.dart';
import '../../domain/entities/voice_recognition_task_info.dart';

class VoiceRecognitionDetailPage extends StatefulWidget {
  final VoiceRecognitionTaskInfo task;

  const VoiceRecognitionDetailPage({super.key, required this.task});

  @override
  State<VoiceRecognitionDetailPage> createState() =>
      _VoiceRecognitionDetailPageState();
}

class _VoiceRecognitionDetailPageState
    extends State<VoiceRecognitionDetailPage> {
  late AudioRecordManager _audioRecordManager;
  late RemoteAudioPlayer _remoteAudioPlayer;
  bool _isDownloading = false;
  String? _audioUrl;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // 初始化音频管理器
    _audioRecordManager = AudioRecordManager(
      onAmplitudesChanged: (amplitudes) {
        setState(() {});
      },
      onRecordingStateChanged: (isRecording) {
        setState(() {});
      },
      onRecordingPathChanged: (path) {
        setState(() {});
      },
      onPlayingStateChanged: (isPlaying) {
        setState(() {});
      },
      onPlayerControllerChanged: (controller) {
        setState(() {});
      },
    );

    // 初始化远程音频播放器
    _remoteAudioPlayer = RemoteAudioPlayer(
      onDownloadStateChanged: (isDownloading) {
        setState(() {
          _isDownloading = isDownloading;
        });
      },
      onLocalPathChanged: (path) {
        if (path == null) {
          debugPrint("◉ 警告: onLocalPathChanged收到了null路径!");
          return;
        }

        setState(() {
          _audioUrl = path;
        });
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 设置AudioRecordManager的context
    if (mounted) {
      _audioRecordManager.setContext(context);
    }

    // 不在initState中初始化，而是在didChangeDependencies中进行，避免在界面未初始化时就修改状态导致报错
    // 防止重复初始化
    if (!_isInitialized) {
      _initAudioPlayer();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _audioRecordManager.dispose();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    if (widget.task.audioFileUrl == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // 初始化音频播放器
      final fileUrl = widget.task.audioFileUrl!;
      debugPrint('音频URL: $fileUrl');

      // 判断是本地文件还是云端URL
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        // 云端音频，使用远程音频播放器下载
        await _remoteAudioPlayer.playRemoteAudio(
          fileUrl,
          _audioRecordManager,
          context: context,
        );
      } else {
        // 本地文件，直接使用
        _audioUrl = fileUrl;
        if (ScreenHelper.isMobile()) {
          // 传递context
          await _audioRecordManager.initPlayer(fileUrl, context: context);
        }
      }
    } catch (e) {
      debugPrint('初始化音频播放器失败: $e');
      ToastUtils.showError('初始化音频播放器失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
                            formatToYMDHMS,
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
            if (widget.task.audioFileUrl != null) ...[
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
                      if (widget.task.localAudioPath != null)
                        _buildInfoRow('本地路径', widget.task.localAudioPath!),
                      _buildInfoRow(
                        widget.task.localAudioPath != null ? '云端地址' : '音频地址',
                        widget.task.githubAudioUrl ?? '未知',
                      ),

                      // if (widget.task.localAudioPath != null)
                      //   _buildInfoRow('本地路径', widget.task.localAudioPath!),

                      // if (widget.task.githubAudioUrl != null)
                      //   _buildInfoRow('云端地址', widget.task.githubAudioUrl!),

                      // _buildInfoRow('播放音频', _audioUrl ?? '未知'),
                      const SizedBox(height: 16),

                      if (_isDownloading) ...[
                        // 加载指示器
                        const DownloadingIndicator(),
                      ] else if (ScreenHelper.isMobile() &&
                          _audioRecordManager.playerController != null &&
                          _audioUrl != null) ...[
                        // 音频波形显示
                        AudioPlayerWaveform(
                          playerController:
                              _audioRecordManager.playerController!,
                          isDesktop: false,
                          recordingPath: _audioUrl!,
                          isPlaying: _audioRecordManager.isPlaying,
                          onPlayToggle:
                              () => _audioRecordManager.togglePlayback(),
                          // 详情页面不需要关闭功能
                          onClose: () {},
                        ),
                      ] else if (_audioUrl != null) ...[
                        // 在桌面端虽然不能使用audio_waveforms的播放器进行播放，但是可以使用AudioPlayerWidget播放
                        // 而且由于初始化时有AudioRecordManager的init，所以云端音频也都下载到本地了，所以全当做本地音频播放即可
                        AudioPlayerWidget(audioUrl: _audioUrl!, autoPlay: true),
                      ] else ...[
                        // 音频准备失败的情况
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '音频文件准备失败 (URL: ${widget.task.audioFileUrl})',
                                style: TextStyle(color: Colors.red),
                              ),
                              if (!_isDownloading)
                                ElevatedButton(
                                  onPressed: _initAudioPlayer,
                                  child: Text('重试加载音频'),
                                ),
                            ],
                          ),
                        ),
                      ],
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
