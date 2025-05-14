import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../common/utils/screen_helper.dart';
import '../../../../../../services/voice_clone_service.dart';
import '../../../../../../common/components/toast_utils.dart';
import '../../../../../../common/components/cus_loading_indicator.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants/constants.dart';
import '../components/audio_operation_widgets.dart';
import 'github_storage_settings_page.dart';

/// audio_waveforms 不支持桌面端，想办法换一个，还是桌面不展示波形和播放试听？？？
/// 2025-05-06 暂时桌面端不展示波形和播放试听
class VoiceClonePage extends StatefulWidget {
  const VoiceClonePage({super.key});

  @override
  State<VoiceClonePage> createState() => _VoiceClonePageState();
}

class _VoiceClonePageState extends State<VoiceClonePage> {
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _cloudAudioUrlController =
      TextEditingController();
  bool _useCloudAudio = false;

  String _selectedModel = 'cosyvoice-v2'; // 默认选择V2模型
  bool _isLoading = false;
  List<ClonedVoice> _clonedVoices = [];

  bool _isUploading = false;
  String? _recordingPath;

  // 音频管理器和远程音频播放器
  late AudioRecordManager _audioRecordManager;
  late RemoteAudioPlayer _remoteAudioPlayer;
  bool _isDownloading = false;

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
        setState(() {
          _recordingPath = path;
        });
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
        setState(() {
          _recordingPath = path;
        });
      },
    );

    if (ScreenHelper.isMobile()) {
      _audioRecordManager.checkMicrophonePermission();
    }
    _refreshVoiceList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在context可用时设置AudioRecordManager的context
    if (mounted) {
      _audioRecordManager.setContext(context);
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _cloudAudioUrlController.dispose();
    _audioRecordManager.dispose();
    super.dispose();
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
  void _startRecording() {
    _audioRecordManager.startRecording(context);
  }

  // 停止录音
  Future<void> _stopRecording() async {
    await _audioRecordManager.stopRecording();
  }

  // 上传音频并克隆声音
  Future<void> _cloneVoice() async {
    if (!_useCloudAudio && _recordingPath == null) {
      ToastUtils.showError('请先录制或选择音频文件');
      return;
    }

    if (_useCloudAudio &&
        (_cloudAudioUrlController.text.isEmpty ||
            (!_cloudAudioUrlController.text.startsWith('http://') &&
                !_cloudAudioUrlController.text.startsWith('https://')))) {
      ToastUtils.showError('请输入有效的云端音频URL，必须以http://或https://开头');
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
        audioPath: _recordingPath ?? '',
        cloudAudioUrl: _useCloudAudio ? _cloudAudioUrlController.text : null,
        prefix: _prefixController.text,
        targetModel: _selectedModel,
      );

      // ToastUtils.showToast('声音克隆成功，音色ID: $voiceId');
      if (!mounted) return;
      commonHintDialog(context, '声音克隆成功', '音色ID: $voiceId');
      _prefixController.clear();
      setState(() {
        _recordingPath = null;
        if (_useCloudAudio) {
          _cloudAudioUrlController.clear();
        }
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
        // 右侧音色列表
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildClonedVoicesList(),
          ),
        ),
      ],
    );
  }

  // 移动端布局 - 垂直布局
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildRecordingSection(),
          const SizedBox(height: 24),
          _buildClonedVoicesList(),
        ],
      ),
    );
  }

  // 录音部分UI
  Widget _buildRecordingSection() {
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

        // 使用通用音频源选择器组件
        AudioSourceSelector(
          useCloudAudio: _useCloudAudio,
          onValueChanged: (value) {
            setState(() {
              _useCloudAudio = value ?? false;
              if (_useCloudAudio) {
                // 切换到云端URL模式时清空本地录音
                _recordingPath = null;
              }
            });
          },
        ),

        // 使用通用云端URL输入组件
        if (_useCloudAudio)
          CloudAudioUrlInput(
            controller: _cloudAudioUrlController,
            enabled: !_isUploading && !_isDownloading,
            onClear: () {
              setState(() {
                _cloudAudioUrlController.clear();
              });
              unfocusHandle();
            },
            onChanged: (value) {
              setState(() {});
            },
            onTryListen:
                () => _remoteAudioPlayer.playRemoteAudio(
                  _cloudAudioUrlController.text,
                  _audioRecordManager,
                  context: context,
                ),
            isDownloading: _isDownloading,
          ),

        const SizedBox(height: 16),

        // 录音波形显示和音频播放相关UI
        if (_isDownloading) ...[
          const DownloadingIndicator(),
        ] else if (!_useCloudAudio && _audioRecordManager.isRecording) ...[
          RecordingWaveform(
            amplitudes: _audioRecordManager.amplitudes,
            isDesktop: isDesktop,
          ),
        ] else if (ScreenHelper.isMobile() &&
            _audioRecordManager.playerController != null &&
            _recordingPath != null) ...[
          // 音频播放波形组件
          AudioPlayerWaveform(
            playerController: _audioRecordManager.playerController!,
            isDesktop: isDesktop,
            recordingPath: _recordingPath!,
            isPlaying: _audioRecordManager.isPlaying,
            onPlayToggle: () => _audioRecordManager.togglePlayback(),
            onClose: () {
              setState(() {
                _recordingPath = null;
              });
            },
          ),
        ] else if (_recordingPath != null) ...[
          // 非移动端或无法显示波形时的文件名显示
          AudioFileInfo(
            recordingPath: _recordingPath!,
            onClose: () {
              setState(() {
                _recordingPath = null;
              });
            },
          ),
        ],

        const SizedBox(height: 16),

        // 录音按钮区域 - 仅在非云端URL模式下显示
        if (!_useCloudAudio)
          RecordingButtonGroup(
            isRecording: _audioRecordManager.isRecording,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
            onPickAudioFile: () {
              // 确保先设置context
              _audioRecordManager.setContext(context);
              _audioRecordManager.pickAudioFile();
            },
            isDesktop: isDesktop,
          ),

        const SizedBox(height: 24),

        // 提交按钮
        SubmitButton(
          isSubmitting: _isUploading,
          isEnabled:
              (_prefixController.text.isNotEmpty) &&
              ((!_useCloudAudio && _recordingPath != null) ||
                  (_useCloudAudio && _cloudAudioUrlController.text.isNotEmpty)),
          onSubmit: _cloneVoice,
          buttonText: '克隆声音',
          loadingText: '处理中...',
          isDesktop: isDesktop,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '创建时间: ${DateFormat(constDatetimeFormat).format(voice.gmtCreate ?? voice.gmtModified ?? DateTime.now())}\n'
                        '状态: ${voice.status}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteVoice(voice),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
