import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/toast_utils.dart';
import '../../../common/components/cus_loading_indicator.dart';
import '../../../common/components/loading_overlay.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../../../common/style/app_colors.dart';
import '../../../models/brief_ai_tools/voice_recognition/voice_recognition_task_info.dart';
import '../../../services/voice_recognition_service.dart';

import '../voice/components/audio_operation_widgets.dart';
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

  String? _recordingPath;

  // 新增云端音频URL输入控制器
  final TextEditingController _cloudAudioUrlController =
      TextEditingController();
  bool _useCloudAudio = false;
  bool _isDownloading = false;

  // 数据库帮助类
  final DBBriefAIToolHelper dbHelper = DBBriefAIToolHelper();

  // 音频管理器和远程音频播放器
  late AudioRecordManager _audioRecordManager;
  late RemoteAudioPlayer _remoteAudioPlayer;

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
- 支持两种音频输入方式：
  - **本地音频文件**：将上传到 Github 公共仓库，需要网络支持
  - **云端音频URL**：直接使用已上传到云端的音频文件地址，无需再次上传
-  **请勿在提交识别任务过程中退出**
- 录制的语音会保存在设备的以下目录:
  - /SuChatFiles/VOICE_REC/voice_recordings
''';

  @override
  void initState() {
    super.initState();

    _selectedModel = _asrModels.first;

    // _languageOptions = VoiceRecognitionService.getLanguageOptions(
    //   _selectedModel,
    // );

    // _selectedLanguage = _languageOptions.first;

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
    _refreshTaskList();
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
    _audioRecordManager.dispose();
    _cloudAudioUrlController.dispose();
    super.dispose();
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

  // 模型变更处理
  void _onModelChanged(CusBriefLLMSpec? value) {
    if (value == null) return;
    setState(() {
      _selectedModel = value;
    });
  }

  // 开始录音
  void _startRecording() {
    _audioRecordManager.startRecording(context);
  }

  // 停止录音
  Future<void> _stopRecording() async {
    await _audioRecordManager.stopRecording();
  }

  // 提交录音识别任务
  Future<void> _submitRecognitionTask() async {
    // 检查是使用本地音频还是云端音频
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

    setState(() {
      _isSubmitting = true;
    });

    // 显示提交中的遮罩
    LoadingOverlay.show(
      context,
      title: '正在提交识别任务...',
      messages: ["请耐心等待一会儿", "请勿退出当前页面", "录音文件过大上传会比较耗时"],
    );

    try {
      // 调用服务提交识别任务
      final taskId = await VoiceRecognitionService.submitRecognitionTask(
        model: _selectedModel,
        audioPath: _recordingPath ?? '',
        cloudAudioUrl: _useCloudAudio ? _cloudAudioUrlController.text : null,
      );

      // 提示任务已提交
      ToastUtils.showToast('录音识别任务已提交，任务ID: $taskId');

      setState(() {
        _recordingPath = null;
        if (_useCloudAudio) {
          _cloudAudioUrlController.clear();
        }
      });

      // 刷新任务列表
      await _refreshTaskList();
    } catch (e) {
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

  // 录音部分UI
  Widget _buildRecordingSection() {
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
            enabled: !_isSubmitting && !_isDownloading,
            onClear: () {
              setState(() {
                _cloudAudioUrlController.clear();
              });
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
          isSubmitting: _isSubmitting,
          isEnabled:
              (!_useCloudAudio && _recordingPath != null) ||
              (_useCloudAudio && _cloudAudioUrlController.text.isNotEmpty),
          onSubmit: _submitRecognitionTask,
          buttonText: '提交识别任务',
          loadingText: '提交中...',
          isDesktop: isDesktop,
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
      } else if (task.taskStatus == 'RUNNING' || task.taskStatus == 'PENDING') {
        color = Colors.blue;
        label = '处理中';
      } else if (task.taskStatus == 'UNKNOWN') {
        color = Colors.grey;
        label = '未知';
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
                  if (task.taskStatus == 'RUNNING' ||
                      task.taskStatus == 'PENDING')
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
