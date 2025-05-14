import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';

import '../../../../../common/utils/screen_helper.dart';
import '../../../../../common/utils/file_picker_helper.dart';
import '../../../../../common/components/toast_utils.dart';
import '../../../../../common/style/app_colors.dart';

import '../../../../common/utils/tools.dart';

/// 音频操作相关的通用组件和函数
/// 包含录音、选择音频文件、播放音频、云端URL输入等功能

/// 波形绘制器
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    if (amplitudes.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    final maxAmplitude = amplitudes
        .reduce((a, b) => a > b ? a : b)
        .clamp(0.0, 1.0);
    final step = width / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final normalizedAmplitude = (amplitudes[i] /
              (maxAmplitude == 0 ? 1 : maxAmplitude))
          .clamp(0.0, 1.0);
      final x = i * step;
      final barHeight = normalizedAmplitude * height * 0.8;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => true;
}

/// 音频录制管理器
class AudioRecordManager {
  final _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _amplitudes = [];
  String? _recordingPath;
  bool _isRecording = false;

  // 音频波形显示
  PlayerController? _playerController;
  bool _isPlaying = false;

  // 保存当前的BuildContext，用于初始化播放器
  BuildContext? _currentContext;

  // 回调函数
  final Function(List<double>) onAmplitudesChanged;
  final Function(bool) onRecordingStateChanged;
  final Function(String?) onRecordingPathChanged;
  final Function(bool) onPlayingStateChanged;
  final Function(PlayerController?) onPlayerControllerChanged;

  AudioRecordManager({
    required this.onAmplitudesChanged,
    required this.onRecordingStateChanged,
    required this.onRecordingPathChanged,
    required this.onPlayingStateChanged,
    required this.onPlayerControllerChanged,
  });

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;
  bool get isPlaying => _isPlaying;
  PlayerController? get playerController => _playerController;
  List<double> get amplitudes => _amplitudes;

  /// 设置当前的BuildContext
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  /// 检查麦克风权限
  Future<bool> checkMicrophonePermission() async {
    if (!ScreenHelper.isMobile()) return true;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ToastUtils.showError('需要麦克风权限以录制声音');
      return false;
    }
    return true;
  }

  /// 开始录音
  Future<void> startRecording(BuildContext context) async {
    if (!await checkMicrophonePermission()) return;

    // 保存当前的BuildContext
    _currentContext = context;

    try {
      // 构建录音文件路径
      final directory = await getVoiceRecordingDir();

      // 使用时间戳命名文件
      final timestamp = fileTs(DateTime.now());
      final filePath = '${directory.path}/recording_$timestamp.m4a';

      // 设置录音配置
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc, // 使用AAC编码
        bitRate: 128000, // 128kbps比特率
        sampleRate: 44100, // 44.1kHz采样率
        numChannels: 1, // 单声道
      );

      // 开始录音
      await _audioRecorder.start(config, path: filePath);

      // 监听振幅变化
      _amplitudes.clear();
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amplitude) {
            _amplitudes.add(amplitude.current);
            if (_amplitudes.length > 100) {
              _amplitudes.removeAt(0);
            }
            onAmplitudesChanged(_amplitudes);
          });

      _recordingPath = filePath;
      _isRecording = true;
      onRecordingStateChanged(_isRecording);
      onRecordingPathChanged(_recordingPath);
    } catch (e) {
      ToastUtils.showError('开始录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _amplitudeSubscription?.cancel();
      _recordingPath = path;
      _isRecording = false;

      onRecordingStateChanged(_isRecording);
      onRecordingPathChanged(_recordingPath);

      if (path != null && ScreenHelper.isMobile()) {
        // 使用保存的context进行初始化
        await initPlayer(path, context: _currentContext);
      }

      ToastUtils.showToast('录音已保存');
    } catch (e) {
      ToastUtils.showError('停止录音失败: $e');
    }
  }

  /// 初始化音频播放器
  Future<void> initPlayer(String path, {BuildContext? context}) async {
    if (!ScreenHelper.isMobile()) return;

    // 使用传入的context或保存的context
    final ctx = context ?? _currentContext;
    if (ctx == null) {
      debugPrint('初始化播放器失败: 缺少BuildContext');
      return;
    }

    try {
      if (_playerController != null) {
        await _playerController!.stopPlayer();
        _playerController!.dispose();
      }

      // 创建新的播放器
      _playerController = PlayerController();
      if (ctx.mounted) {
        await _playerController!.preparePlayer(
          path: path,
          noOfSamples: MediaQuery.of(ctx).size.width ~/ 8,
        );
      }

      // 添加播放完成监听
      _playerController!.onCompletion.listen((_) {
        // 播放完成后播放标志置为false
        _isPlaying = false;
        onPlayingStateChanged(_isPlaying);
      });

      onPlayerControllerChanged(_playerController);
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
    }
  }

  /// 播放或暂停录音
  Future<void> togglePlayback() async {
    if (!ScreenHelper.isMobile() || _playerController == null) return;

    try {
      if (_isPlaying) {
        await _playerController!.pausePlayer();
      } else {
        await _playerController!.startPlayer();
        // 设置播放完成模式为暂停可以重复播放(默认是stop，播放完资源就释放了)
        _playerController!.setFinishMode(finishMode: FinishMode.pause);
      }

      _isPlaying = !_isPlaying;
      onPlayingStateChanged(_isPlaying);
    } catch (e) {
      ToastUtils.showError('播放操作失败: $e');
    }
  }

  /// 选择音频文件
  Future<void> pickAudioFile() async {
    File? result = await FilePickerHelper.pickAndSaveFile(
      fileType: CusFileType.audio,
    );

    if (result != null) {
      _recordingPath = result.path;
      onRecordingPathChanged(_recordingPath);

      // 使用保存的context进行初始化
      await initPlayer(result.path, context: _currentContext);

      ToastUtils.showToast('已选择文件: ${result.path.split("/").last}');
    }
  }

  /// 清理资源
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _playerController?.dispose();
    _currentContext = null;
  }
}

/// 播放远程音频
class RemoteAudioPlayer {
  bool _isDownloading = false;

  final Function(bool) onDownloadStateChanged;
  final Function(String?) onLocalPathChanged;

  RemoteAudioPlayer({
    required this.onDownloadStateChanged,
    required this.onLocalPathChanged,
  });

  bool get isDownloading => _isDownloading;

  /// 播放远程音频文件
  Future<void> playRemoteAudio(
    String url,
    AudioRecordManager audioManager, {
    BuildContext? context,
  }) async {
    // if (ScreenHelper.isDesktop()) {
    //   ToastUtils.showToast('桌面端不支持在线播放');
    //   return;
    // }

    // 虽然audio_waveforms不支持桌面端，也不支持在线
    // 但是可以都下载下来，桌面端使用AudioPlayerWidget播放，没有波形显示而已
    _isDownloading = true;
    onDownloadStateChanged(_isDownloading);

    try {
      // 下载远程音频文件到临时目录
      final tempDir = await getDioDownloadDir();
      final fileName = url.split('/').last;
      final localPath = '${tempDir.path}/$fileName';

      // 检查文件是否已经存在
      final localFile = File(localPath);
      if (!await localFile.exists()) {
        // 显示下载进度
        ToastUtils.showToast('正在下载音频文件...');

        try {
          // 使用dio下载文件
          await Dio().download(
            url,
            localPath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                debugPrint(
                  '下载进度: ${(received / total * 100).toStringAsFixed(0)}%',
                );
              }
            },
          );
          ToastUtils.showToast('下载完成');
        } catch (e) {
          ToastUtils.showError('下载音频文件失败: $e');
          _isDownloading = false;
          onDownloadStateChanged(_isDownloading);
          return;
        }
      }

      // 先调用回调告知路径已更新
      onLocalPathChanged(localPath);

      // 然后再初始化播放器
      if (context != null && context.mounted) {
        // 设置AudioManager的context
        audioManager.setContext(context);
        // 初始化播放器
        await audioManager.initPlayer(localPath, context: context);
      }
    } catch (e) {
      ToastUtils.showError('准备远程音频失败: $e');
    } finally {
      _isDownloading = false;
      onDownloadStateChanged(_isDownloading);
    }
  }
}

/// 云端URL输入组件
class CloudAudioUrlInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final Function() onClear;
  final Function(String) onChanged;
  final Function() onTryListen;
  final bool isDownloading;

  const CloudAudioUrlInput({
    super.key,
    required this.controller,
    this.enabled = true,
    required this.onClear,
    required this.onChanged,
    required this.onTryListen,
    this.isDownloading = false,
  });

  @override
  State<CloudAudioUrlInput> createState() => _CloudAudioUrlInputState();
}

class _CloudAudioUrlInputState extends State<CloudAudioUrlInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        children: [
          TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入云端音频URL (http://或https://)',
              prefixIcon: Icon(Icons.link),
              suffixIcon:
                  widget.controller.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: widget.onClear,
                      )
                      : null,
            ),
            onChanged: widget.onChanged,
          ),
          if (widget.controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.isDownloading ? null : widget.onTryListen,
                    icon: Icon(Icons.play_circle_outline),
                    label: Text(widget.isDownloading ? '准备中...' : '试听'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 音频源选择组件（本地录音或云端URL）
class AudioSourceSelector extends StatelessWidget {
  final bool useCloudAudio;
  final Function(bool?) onValueChanged;

  const AudioSourceSelector({
    super.key,
    required this.useCloudAudio,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Checkbox(value: useCloudAudio, onChanged: onValueChanged),
          Text('使用云端音频URL', style: TextStyle(fontWeight: FontWeight.w500)),
          IconButton(
            icon: Icon(Icons.info_outline, size: 18),
            onPressed: () {
              ToastUtils.showToast('输入公开可访问的音频文件URL，无需上传到GitHub');
            },
          ),
        ],
      ),
    );
  }
}

/// 录音波形显示组件
class RecordingWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final bool isDesktop;

  const RecordingWaveform({
    super.key,
    required this.amplitudes,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: isDesktop ? 150 : 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: CustomPaint(
              size: Size(double.infinity, isDesktop ? 120 : 80),
              painter: WaveformPainter(
                amplitudes: amplitudes,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '正在录音...',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// 音频播放波形组件
class AudioPlayerWaveform extends StatelessWidget {
  final PlayerController playerController;
  final bool isDesktop;
  final String recordingPath;
  final bool isPlaying;
  final Function() onPlayToggle;
  final Function() onClose;

  const AudioPlayerWaveform({
    super.key,
    required this.playerController,
    this.isDesktop = false,
    required this.recordingPath,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (ScreenHelper.isMobile())
          Center(
            child: Container(
              height: isDesktop ? 150 : 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: AudioFileWaveforms(
                size: Size(
                  isDesktop
                      ? MediaQuery.of(context).size.width * 0.3
                      : MediaQuery.of(context).size.width - 80,
                  isDesktop ? 120 : 80,
                ),
                playerController: playerController,
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
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ScreenHelper.isMobile())
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: onPlayToggle,
                color: AppColors.primary,
                iconSize: 32,
              ),
            Expanded(
              child: Text(
                recordingPath.split('/').last,
                maxLines: 4,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          ],
        ),
      ],
    );
  }
}

/// 音频文件信息显示（用于桌面端）
class AudioFileInfo extends StatelessWidget {
  final String recordingPath;
  final Function() onClose;

  const AudioFileInfo({
    super.key,
    required this.recordingPath,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.audio_file, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              recordingPath.split('/').last,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

/// 录音按钮组
class RecordingButtonGroup extends StatelessWidget {
  final bool isRecording;
  final Function() onStartRecording;
  final Function() onStopRecording;
  final Function() onPickAudioFile;
  final bool isDesktop;

  const RecordingButtonGroup({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPickAudioFile,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 录音按钮
        ElevatedButton.icon(
          onPressed: isRecording ? onStopRecording : onStartRecording,
          icon: Icon(isRecording ? Icons.stop : Icons.mic),
          label: Text(isRecording ? '停止录音' : '开始录音'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isRecording ? Colors.red : AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                isDesktop
                    ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                    : null,
          ),
        ),
        // 选择录音文件按钮
        ElevatedButton.icon(
          onPressed: isRecording ? null : onPickAudioFile,
          icon: const Icon(Icons.folder_open),
          label: const Text('选择音频'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding:
                isDesktop
                    ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                    : null,
          ),
        ),
      ],
    );
  }
}

/// 下载中指示器
class DownloadingIndicator extends StatelessWidget {
  const DownloadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('正在准备音频文件...'),
        ],
      ),
    );
  }
}

/// 提交按钮
class SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final bool isEnabled;
  final Function() onSubmit;
  final String buttonText;
  final String loadingText;
  final bool isDesktop;

  const SubmitButton({
    super.key,
    required this.isSubmitting,
    required this.isEnabled,
    required this.onSubmit,
    required this.buttonText,
    this.loadingText = '处理中...',
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled && !isSubmitting ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 16 : 12,
            horizontal: isDesktop ? 32 : 16,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child:
            isSubmitting
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(loadingText),
                  ],
                )
                : Text(buttonText),
      ),
    );
  }
}
