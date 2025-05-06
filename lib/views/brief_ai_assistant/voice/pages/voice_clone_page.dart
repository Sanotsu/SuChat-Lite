import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

import '../../../../../../common/constants/constants.dart';
import '../../../../../../common/utils/tools.dart';
import '../../../../../../common/utils/screen_helper.dart';
import '../../../../../../services/voice_clone_service.dart';
import '../../../../../../common/style/app_colors.dart';
import '../../../../../../common/components/toast_utils.dart';
import '../../../../../../common/components/cus_loading_indicator.dart';
import 'github_storage_settings_page.dart';

/// TODO audio_waveforms 不支持桌面端，想办法换一个，还是桌面不展示波形和播放试听？？？
class VoiceClonePage extends StatefulWidget {
  const VoiceClonePage({super.key});

  @override
  State<VoiceClonePage> createState() => _VoiceClonePageState();
}

class _VoiceClonePageState extends State<VoiceClonePage> {
  final TextEditingController _prefixController = TextEditingController();
  String _selectedModel = 'cosyvoice-v2'; // 默认选择V2模型
  bool _isLoading = false;
  List<ClonedVoice> _clonedVoices = [];

  bool _isUploading = false;
  bool _isRecording = false;
  String? _recordingPath;

  // 音频录制相关
  final _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _amplitudes = [];

  // 音频波形显示
  PlayerController? _playerController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    if (ScreenHelper.isMobile()) {
      _checkMicrophonePermission();
    }
    _refreshVoiceList();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _playerController?.dispose();
    super.dispose();
  }

  // 检查麦克风权限
  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ToastUtils.showError('需要麦克风权限以录制声音');
    }
  }

  // 刷新克隆音色列表
  Future<void> _refreshVoiceList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final voices = await VoiceCloneService.getClonedVoices();
      setState(() {
        _clonedVoices = voices;
      });
    } catch (e) {
      ToastUtils.showError('获取音色列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 开始录音
  Future<void> _startRecording() async {
    try {
      // 检查权限
      if (!await _audioRecorder.hasPermission()) {
        ToastUtils.showError('需要麦克风权限以录制声音');
        return;
      }

      // 准备录制路径
      final tempDir = await getVoiceCloneRecordDir();
      final filePath =
          '${tempDir.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 设置录音配置
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc, // 使用AAC编码
        bitRate: 128000, // 128kbps比特率
        sampleRate: 44100, // 44.1kHz采样率
        numChannels: 1, // 单声道
      );

      // 开始录音
      await _audioRecorder.start(config, path: filePath);

      // 监听录音振幅以更新波形
      _amplitudes.clear();
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amplitude) {
            setState(() {
              // 将dB值转换为0-1之间的相对振幅
              // dB通常为负值，0dB为最大，-160dB为最小
              final normalized = (amplitude.current + 160) / 160;
              _amplitudes.add(normalized.clamp(0.0, 1.0));

              // 保持数组在合理大小内
              if (_amplitudes.length > 100) {
                _amplitudes.removeAt(0);
              }
            });
          });

      setState(() {
        _isRecording = true;
        _recordingPath = filePath;
      });

      ToastUtils.showToast('开始录音...');
    } catch (e) {
      ToastUtils.showError('录音启动失败: $e');
    }
  }

  // 停止录音
  Future<void> _stopRecording() async {
    try {
      // 停止录音并获取录音文件路径
      final path = await _audioRecorder.stop();

      // 取消振幅监听
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });

        // 录音完成后初始化播放器以便预览录音
        _initPlayer(path);

        ToastUtils.showToast('录音完成: ${path.split('/').last}');
      } else {
        setState(() {
          _isRecording = false;
          _recordingPath = null;
        });
        ToastUtils.showError('录音失败');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      ToastUtils.showError('停止录音失败: $e');
    }
  }

  // 初始化音频播放器
  Future<void> _initPlayer(String path) async {
    try {
      // 释放现有的播放器
      _playerController?.dispose();

      // 创建新的播放器
      _playerController = PlayerController();
      await _playerController!.preparePlayer(
        path: path,
        noOfSamples: MediaQuery.of(context).size.width ~/ 8,
      );

      // 添加播放完成监听
      _playerController!.onCompletion.listen((_) {
        // 播放完成后播放标志置为false
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
    }
  }

  // 选择音频文件
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _recordingPath = path;
        });

        // 初始化播放器以便预览选择的音频
        _initPlayer(path);

        ToastUtils.showToast('已选择文件: ${result.files.first.name}');
      }
    }
  }

  // 播放或暂停录音
  void _togglePlayback() async {
    if (_playerController == null) return;

    try {
      if (_isPlaying) {
        await _playerController!.pausePlayer();
      } else {
        await _playerController!.startPlayer();
        // 设置播放完成模式为暂停可以重复播放(默认是stop，播放完资源就释放了)
        _playerController!.setFinishMode(finishMode: FinishMode.pause);
      }

      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      ToastUtils.showError('播放操作失败: $e');
    }
  }

  // 上传音频并克隆声音
  Future<void> _cloneVoice() async {
    if (_recordingPath == null) {
      ToastUtils.showError('请先录制或选择音频文件');
      return;
    }

    if (_prefixController.text.isEmpty) {
      ToastUtils.showError('请输入音色前缀');
      return;
    }

    if (!RegExp(r'^[a-z0-9]{1,9}$').hasMatch(_prefixController.text)) {
      ToastUtils.showError('前缀仅允许数字和小写字母，长度为1-9个字符');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final voiceId = await VoiceCloneService.cloneVoice(
        audioPath: _recordingPath!,
        prefix: _prefixController.text,
        targetModel: _selectedModel,
      );

      ToastUtils.showToast('声音克隆成功，音色ID: $voiceId');
      _prefixController.clear();
      setState(() {
        _recordingPath = null;
        _playerController?.dispose();
        _playerController = null;
      });

      // 刷新音色列表
      await _refreshVoiceList();
    } catch (e) {
      ToastUtils.showError('声音克隆失败: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // 删除克隆的音色
  Future<void> _deleteVoice(ClonedVoice voice) async {
    if (voice.voiceId == null) return;

    try {
      await VoiceCloneService.deleteClonedVoice(voice.voiceId!);
      ToastUtils.showToast('删除音色成功');
      await _refreshVoiceList();
    } catch (e) {
      ToastUtils.showError('删除音色失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 判断是否为桌面平台
    final isDesktop = ScreenHelper.isDesktop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CosyVoice声音复刻'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'GitHub存储设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GitHubStorageSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CusLoadingIndicator(text: '加载中...'))
              : isDesktop
              // 桌面端布局 - 左右两栏
              ? _buildDesktopLayout()
              // 移动端布局 - 保持原有的垂直布局
              : _buildMobileLayout(),
    );
  }

  // 桌面端布局 - 左右两栏
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧录音部分
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildRecordingSection(),
          ),
        ),

        // 中间分隔线
        Container(
          width: 1,
          height: double.infinity,
          color: Colors.grey.withValues(alpha: 0.3),
        ),

        // 右侧音色列表
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // 标题部分
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                child: Row(
                  children: [
                    const Text(
                      '已克隆的音色',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshVoiceList,
                    ),
                  ],
                ),
              ),

              // 列表部分 - 使用Expanded包裹让它占据剩余空间
              Expanded(
                child:
                    _clonedVoices.isEmpty
                        ? const Center(
                          child: Text(
                            '暂无克隆音色',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            24.0,
                            8.0,
                            24.0,
                            24.0,
                          ),
                          itemCount: _clonedVoices.length,
                          itemBuilder: (context, index) {
                            final voice = _clonedVoices[index];

                            return Card(
                              elevation: 0.5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: Text(
                                  '${voice.voiceId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '创建时间: ${DateFormat(constDatetimeFormat).format(voice.gmtCreate ?? voice.gmtModified ?? DateTime.now())}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDeleteVoice(voice),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 移动端布局 - 原有的垂直布局
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordingSection(),
          const SizedBox(height: 24),
          _buildClonedVoicesList(),
        ],
      ),
    );
  }

  // 录音和上传部分UI
  Widget _buildRecordingSection() {
    // 判断是否为桌面端
    final isDesktop = ScreenHelper.isDesktop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创建新音色',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _prefixController,
          decoration: const InputDecoration(
            labelText: '音色前缀',
            hintText: '请输入1-9个小写字母或数字作为前缀',
            border: OutlineInputBorder(),
          ),
          maxLength: 9,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('目标模型: '),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedModel,
              items: const [
                DropdownMenuItem(
                  value: 'cosyvoice-v1',
                  child: Text('CosyVoice V1'),
                ),
                DropdownMenuItem(
                  value: 'cosyvoice-v2',
                  child: Text('CosyVoice V2'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedModel = value!;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 录音波形显示
        if (_isRecording) ...[
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
                  amplitudes: _amplitudes,
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
        ] else if (_playerController != null && _recordingPath != null) ...[
          // 音频播放波形
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
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _togglePlayback,
                color: AppColors.primary,
                iconSize: 32,
              ),
              Expanded(
                child: Text(
                  _recordingPath?.split('/').last ?? '',
                  maxLines: 4,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _recordingPath = null;
                    _playerController?.dispose();
                    _playerController = null;
                    _isPlaying = false;
                  });
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 录音按钮
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? '停止录音' : '开始录音'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    isDesktop
                        ? const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        )
                        : null,
              ),
            ),
            // 选择录音文件按钮
            ElevatedButton.icon(
              onPressed: _isRecording ? null : _pickAudioFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择音频'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding:
                    isDesktop
                        ? const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        )
                        : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_isRecording ||
                        _recordingPath == null ||
                        _prefixController.text.isEmpty ||
                        _isUploading)
                    ? null
                    : _cloneVoice,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 16 : 12,
                horizontal: isDesktop ? 32 : 16,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child:
                _isUploading
                    ? const Row(
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
                        Text('处理中...'),
                      ],
                    )
                    : const Text('克隆声音'),
          ),
        ),
      ],
    );
  }

  // 克隆音色列表UI
  Widget _buildClonedVoicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '已克隆的音色',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshVoiceList,
            ),
          ],
        ),

        const SizedBox(height: 8),
        if (_clonedVoices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                '暂无克隆音色',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            // 在桌面端使用滚动物理效果，让长列表可以独立滚动
            physics:
                ScreenHelper.isDesktop()
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
            itemCount: _clonedVoices.length,
            itemBuilder: (context, index) {
              final voice = _clonedVoices[index];

              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    '${voice.voiceId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '创建时间: ${DateFormat(constDatetimeFormat).format(voice.gmtCreate ?? voice.gmtModified ?? DateTime.now())}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteVoice(voice),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // 确认删除对话框
  Future<void> _confirmDeleteVoice(ClonedVoice voice) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除音色 "${voice.voiceId}" 吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVoice(voice);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

// 自定义波形画笔
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final width = size.width;

    // 计算每个点的x坐标间距
    final dx = width / (amplitudes.length - 1);

    // 绘制波形
    for (int i = 0; i < amplitudes.length - 1; i++) {
      final x1 = i * dx;
      final y1 = centerY * (1 - amplitudes[i]);
      final x2 = (i + 1) * dx;
      final y2 = centerY * (1 - amplitudes[i + 1]);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes || oldDelegate.color != color;
  }
}
