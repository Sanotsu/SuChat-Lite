import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/toast_utils.dart';
import '../../../common/components/cus_loading_indicator.dart';
import '../../../common/components/loading_overlay.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/utils/tools.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../common/style/app_colors.dart';
import '../../../services/voice_recognition_service.dart';

import '../voice/pages/github_storage_settings_page.dart';
import 'voice_recognition_detail_page.dart';

/// 录音识别页面
class VoiceRecognitionPage extends StatefulWidget {
  const VoiceRecognitionPage({super.key});

  @override
  State<VoiceRecognitionPage> createState() => _VoiceRecognitionPageState();
}

class _VoiceRecognitionPageState extends State<VoiceRecognitionPage> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<VoiceRecognitionTaskInfo> _recognitionTasks = [];

  bool _isRecording = false;
  String? _recordingPath;

  // 数据库帮助类
  final DBBriefAIToolHelper dbHelper = DBBriefAIToolHelper();

  // 音频录制相关
  final _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final List<double> _amplitudes = [];

  // 音频波形显示
  PlayerController? _playerController;
  bool _isPlaying = false;

  // 默认选中的模型
  late CusBriefLLMSpec _selectedModel;

  // 支持的模型列表
  // 2025-05-07 都是阿里云的模型，都是先提交job，再查询结果，然后下载json文件解析
  // 所以模型预设好，但要检测到用户有自己的阿里云AK才能提交成功
  final List<CusBriefLLMSpec> _asrModels = [
    CusBriefLLMSpec(
      ApiPlatform.aliyun,
      "paraformer-v1",
      LLModelType.asr,
      description: '仅支持中英文',
      cusLlmSpecId: const Uuid().v4(),
    ),
    CusBriefLLMSpec(
      ApiPlatform.aliyun,
      "paraformer-v2",
      LLModelType.asr,
      description: '中(部分方言)英日韩',
      cusLlmSpecId: const Uuid().v4(),
    ),
    CusBriefLLMSpec(
      ApiPlatform.aliyun,
      "paraformer-8k-v1",
      LLModelType.asr,
      description: '仅支持中文',
      cusLlmSpecId: const Uuid().v4(),
    ),
    CusBriefLLMSpec(
      ApiPlatform.aliyun,
      "paraformer-8k-v2",
      LLModelType.asr,
      description: '仅支持中文',
      cusLlmSpecId: const Uuid().v4(),
    ),
    CusBriefLLMSpec(
      ApiPlatform.aliyun,
      "paraformer-mtl-v1",
      LLModelType.asr,
      description: '中(部分方言)英日韩法意等',
      cusLlmSpecId: const Uuid().v4(),
    ),
    CusBriefLLMSpec(
      ApiPlatform.aliyun,
      "sensevoice-v1",
      LLModelType.asr,
      description: '中英粤日韩俄法意西德等',
      cusLlmSpecId: const Uuid().v4(),
    ),
  ];

  /// 2025-05-07 暂时不支持选择录音语言，因为默认使用auto就足够了
  /// 这些先保留
  // 语言选择，默认中文
  // CusLabel _selectedLanguage = CusLabel(cnLabel: "中文", value: "zh");

  // 支持的语言列表
  // late List<CusLabel> _languageOptions;

  String note = '''
- 使用**阿里云**平台的录音语音识别服务
- Paraformer
  - `paraformer-v2` : 中(部分方言)英日韩
  - `paraformer-8k-v2` : 仅中文
  - `paraformer-v1` : 仅中英文
  - `paraformer-8k-v1` : 仅中文
  - `paraformer-mtl-v1`: 中(部分方言)英日韩法意等
  - 单价：0.00008元/秒
- SenseVoice
  - `sensevoice-v1` : 中英粤日韩俄法意西德等
  - 单价：2.52元/小时
- 音频文件不超过2GB；12 小时以内
- 暂时每次只支持识别 1 个录音文件
- 文件会上传到 Github 公共仓库，需要网络支持
-  **请勿在提交识别任务过程中退出**
- 录制的语音会保存在设备的以下目录:
  - /SuChatFiles/voice_recognition_records
''';

  @override
  void initState() {
    super.initState();

    _selectedModel = _asrModels.first;

    // _languageOptions = VoiceRecognitionService.getLanguageOptions(
    //   _selectedModel,
    // );

    // _selectedLanguage = _languageOptions.first;

    if (ScreenHelper.isMobile()) {
      _checkMicrophonePermission();
    }
    _refreshTaskList();
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    if (ScreenHelper.isMobile()) {
      _playerController?.dispose();
    }
    super.dispose();
  }

  // 检查麦克风权限
  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ToastUtils.showError('需要麦克风权限以录制声音');
    }
  }

  // 刷新识别任务列表
  Future<void> _refreshTaskList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 从服务获取本地存储的任务列表
      final tasks = await VoiceRecognitionService.getRecognitionTasks();
      setState(() {
        _recognitionTasks = tasks;
      });
    } catch (e) {
      ToastUtils.showError('获取识别任务列表失败: $e');
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
      final tempDir = await getVoiceRecognitionRecordDir();
      final filePath =
          '${tempDir.path}/recognition_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
    if (!ScreenHelper.isMobile()) {
      return;
    }

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
    if (!ScreenHelper.isMobile() || _playerController == null) return;

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

  // 提交录音识别任务
  Future<void> _submitRecognitionTask() async {
    if (_recordingPath == null) {
      ToastUtils.showError('请先录制或选择音频文件');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 显示提交中的遮罩
    LoadingOverlay.show(
      context,
      title: '正在提交识别任务...',
      messages: ["请耐心等待一会儿", "请勿退出当前页面", "如果录音文件过大上传会比较耗时"],
    );

    try {
      // 调用服务提交识别任务
      final taskId = await VoiceRecognitionService.submitRecognitionTask(
        model: _selectedModel,
        audioPath: _recordingPath!,
        // languageHint: _selectedLanguage.value as String,
      );

      // 提示任务已提交
      ToastUtils.showToast('录音识别任务已提交，任务ID: $taskId');

      setState(() {
        _recordingPath = null;
        if (ScreenHelper.isMobile()) {
          _playerController?.dispose();
          _playerController = null;
        }
      });

      // 刷新任务列表
      await _refreshTaskList();
    } catch (e) {
      // ToastUtils.showError('提交识别任务失败: $e');
      if (!mounted) return;
      commonExceptionDialog(context, '提交识别任务失败', e.toString());
    } finally {
      // 隐藏遮罩
      LoadingOverlay.hide();

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 检查任务状态
  Future<void> _checkTaskStatus(String taskId) async {
    try {
      final updatedTask = await VoiceRecognitionService.queryTaskStatus(taskId);

      // VoiceRecognitionService.queryTaskStatus方法现在已经处理了数据库操作
      // 不需要在这里再次处理数据库插入操作

      if (updatedTask.taskStatus == 'SUCCEEDED') {
        ToastUtils.showSuccess('识别完成');
      } else if (updatedTask.taskStatus == 'FAILED') {
        ToastUtils.showError('识别失败: ${updatedTask.errorMessage}');
      } else {
        ToastUtils.showToast('任务状态: ${updatedTask.taskStatus}');
      }

      // 刷新列表
      await _refreshTaskList();
    } catch (e) {
      debugPrint('检查录音识别任务状态失败: $e');
      ToastUtils.showError('检查录音识别任务状态失败: $e');
    }
  }

  // 删除识别任务
  Future<void> _deleteTask(VoiceRecognitionTaskInfo task) async {
    try {
      await VoiceRecognitionService.deleteRecognitionTask(task.taskId);
      ToastUtils.showToast('删除任务成功');
      await _refreshTaskList();
    } catch (e) {
      ToastUtils.showError('删除任务失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 判断是否为桌面平台
    final isDesktop = ScreenHelper.isDesktop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('录音文件识别'),
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
          IconButton(
            onPressed: () {
              ScreenHelper.isDesktop()
                  ? commonMarkdwonHintDialog(context, "录音识别使用说明", note)
                  : commonMDHintModalBottomSheet(context, "录音识别使用说明", note);
            },
            icon: const Icon(Icons.info_outline),
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

        // 右侧识别结果列表
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
                      '识别任务列表',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshTaskList,
                    ),
                  ],
                ),
              ),

              // 列表部分 - 使用Expanded包裹让它占据剩余空间
              Expanded(
                child:
                    _recognitionTasks.isEmpty
                        ? const Center(
                          child: Text(
                            '暂无识别任务',
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
                          itemCount: _recognitionTasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(_recognitionTasks[index]);
                          },
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 移动端布局 - 垂直布局
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordingSection(),
          const Divider(height: 24),
          _buildTaskListSection(),
        ],
      ),
    );
  }

  // 当选中的模型变化后，要对应修改该模型支持的语言列表
  _onModelChanged(CusBriefLLMSpec? value) {
    setState(() {
      _selectedModel = value!;
    });

    // // 根据选中的模型修改语言列表
    // _languageOptions.clear();
    // _languageOptions.addAll(
    //   VoiceRecognitionService.getLanguageOptions(_selectedModel),
    // );

    // _selectedLanguage = _languageOptions.first;

    // setState(() {});
  }

  // 录音和上传部分UI
  Widget _buildRecordingSection() {
    // 判断是否为桌面端
    final isDesktop = ScreenHelper.isDesktop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创建识别任务',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('选择模型', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Expanded(
              child: buildDropdownButton2<CusBriefLLMSpec?>(
                height: 48,
                value: _selectedModel,
                items: _asrModels,
                alignment: Alignment.centerLeft,
                hintLabel: "选择模型",
                onChanged: _onModelChanged,
                itemToString:
                    (e) => "${(e as CusBriefLLMSpec).model} (${e.description})",
              ),
            ),

            // 2025-05-07 暂时不支持选择录音语言，因为默认使用auto就足够了
            // Expanded(
            //   child: buildDropdownButton2<CusLabel?>(
            //     height: 32,
            //     value: _selectedLanguage,
            //     items: _languageOptions,
            //     hintLabel: "录音语言",
            //     onChanged: (value) {
            //       setState(() {
            //         _selectedLanguage = value!;
            //       });
            //     },
            //     itemToString: (e) => "${(e as CusLabel).cnLabel} (${e.value})",
            //   ),
            // ),
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
        ] else if (ScreenHelper.isMobile() &&
            _playerController != null &&
            _recordingPath != null) ...[
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
        ] else if (_recordingPath != null) ...[
          // 非移动端或无法显示波形时的文件名显示
          Container(
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
                    _recordingPath?.split('/').last ?? '',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _recordingPath = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
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
                (_isRecording || _recordingPath == null || _isSubmitting)
                    ? null
                    : _submitRecognitionTask,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 16 : 12,
                horizontal: isDesktop ? 32 : 16,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child:
                _isSubmitting
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
                        Text('提交中...'),
                      ],
                    )
                    : const Text('提交识别任务'),
          ),
        ),
      ],
    );
  }

  // 任务列表部分UI (移动端)
  Widget _buildTaskListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '识别任务列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshTaskList,
            ),
          ],
        ),

        const SizedBox(height: 8),
        if (_recognitionTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                '暂无识别任务',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recognitionTasks.length,
            itemBuilder: (context, index) {
              return _buildTaskCard(_recognitionTasks[index]);
            },
          ),
      ],
    );
  }

  // 构建任务卡片
  Widget _buildTaskCard(VoiceRecognitionTaskInfo task) {
    // 构建状态徽章
    Widget statusBadge() {
      Color color;
      String label;

      if (task.taskStatus == 'SUCCEEDED') {
        color = Colors.green;
        label = '已完成';
      } else if (task.taskStatus == 'FAILED') {
        color = Colors.red;
        label = '失败';
      } else if (task.taskStatus == 'RUNNING') {
        color = Colors.blue;
        label = '处理中';
      } else {
        color = Colors.orange;
        label = '等待中';
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      );
    }

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VoiceRecognitionDetailPage(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.audio_file, size: 32, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '任务编号: ${task.taskId}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            // Expanded(
                            //   child: Text(
                            //     '语言: ${_languageOptions.firstWhere((lang) => lang.value == task.languageHint, orElse: () => _languageOptions.first).cnLabel}',
                            //     style: TextStyle(fontSize: 12),
                            //   ),
                            // ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '模型: ${task.llmSpec?.model ?? '未知'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),

                        if (task.gmtCreate != null)
                          Text(
                            '创建时间: ${DateFormat(constDatetimeFormat).format(task.gmtCreate!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  statusBadge(),
                ],
              ),

              // 识别结果或操作按钮
              if (task.taskStatus == 'SUCCEEDED' &&
                  task.recognizedText != null) ...[
                Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    '识别结果:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    VoiceRecognitionService.cleanText(task.recognizedText!),
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              if (task.taskStatus == 'FAILED') ...[
                Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    '失败原因:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    VoiceRecognitionService.cleanText(task.errorMessage ?? ''),
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // 操作按钮
              Divider(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (task.taskStatus != 'SUCCEEDED' &&
                      task.taskStatus != 'FAILED')
                    TextButton.icon(
                      onPressed: () => _checkTaskStatus(task.taskId),
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('检查状态'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _confirmDeleteTask(task),
                    icon: Icon(Icons.delete, size: 18),
                    label: Text('删除'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 确认删除对话框
  Future<void> _confirmDeleteTask(VoiceRecognitionTaskInfo task) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除此识别任务吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(task);
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
