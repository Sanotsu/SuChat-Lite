import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../common/components/toast_utils.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../models/brief_ai_tools/media_generation_history/media_generation_history.dart';
import '../../../services/qwen_tts_service.dart';
import '../../../services/voice_generation_service.dart';
import '../common/media_generation_base.dart';
import 'mime_voice_manager.dart';
import 'audio_player_widget.dart';
import 'voice_trial_listening_page.dart';
import '../../../common/components/loading_overlay.dart';

class BriefVoiceScreen extends MediaGenerationBase {
  const BriefVoiceScreen({super.key});

  @override
  State<BriefVoiceScreen> createState() => _BriefVoiceScreenState();
}

class _BriefVoiceScreenState
    extends MediaGenerationBaseState<BriefVoiceScreen> {
  @override
  List<LLModelType> get mediaTypes => [LLModelType.tts];

  @override
  String get title => '语音合成';

  @override
  String get note => '''
- 目前只支持**阿里云**平台的语音合成服务
- 先选择平台模型和音色，再输入要合成的文本
- 支持:
  - Qwen-TTS
  - CosyVoice的V1和V2
  - Sambert 
- 生成的语音会保存在设备的以下目录:
  - /SuChat/voice_generation
''';

  @override
  Widget buildMediaOptions() {
    return SizedBox(
      width: 110,
      child: buildDropdownButton2<AliyunVoiceType?>(
        height: 48,
        value: selectedVoice,
        items: voiceOptions,
        hintLabel: "选择音色",
        onChanged:
            isGenerating
                ? null
                : (value) {
                  setState(() => selectedVoice = value!);
                },
        itemToString: (e) => (e as AliyunVoiceType).name,
      ),
    );
  }

  @override
  Widget buildGeneratedList() {
    return FutureBuilder<List<MediaGenerationHistory>>(
      future: dbHelper.queryMediaGenerationHistory(
        modelTypes: [LLModelType.tts],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('暂无生成记录'));
        }

        final tasks = snapshot.data!;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
        );
      },
    );
  }

  @override
  Future<void> generate() async {
    if (!checkGeneratePrerequisites()) return;

    setState(() => isGenerating = true);
    
    // 显示生成遮罩
    LoadingOverlay.showVoiceGeneration(context, onCancel: () {
      // 取消生成
      setState(() => isGenerating = false);
    });

    try {
      final voiceDir = await getVoiceGenDir();
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }

      // 生成文件名，使用模型名、时间戳、文本标题
      final timestamp = DateFormat(constDatetimeSuffix).format(DateTime.now());

      // 移除所有空白字符(制表符、换行符等)
      var title = promptController.text.trim().replaceAll(RegExp(r'\s+'), '');

      title = title.length > 10 ? title.substring(0, 10) : title;

      final filename =
          '${selectedModel!.model}_${selectedVoice.name}_${timestamp}_$title.mp3';
      final outputPath = path.join(voiceDir.path, filename);

      // 生成语音
      var voicePath = "";
      if (selectedModel!.model.contains('qwen-tts')) {
        voicePath = await QwenTtsService.generateVoice(
          model: selectedModel!,
          text: promptController.text.trim(),
          voice: selectedVoice.id,
        );
      } else if (selectedModel!.model.contains('cosyvoice-v1') ||
          selectedModel!.model.contains('cosyvoice-v2') ||
          selectedModel!.model.contains('sambert')) {
        voicePath = await VoiceGenerationService.generateVoice(
          model: selectedModel!,
          text: promptController.text.trim(),
          voice: selectedVoice.id,
        );
      } else {
        ToastUtils.showError('不支持的模型: ${selectedModel!.model}');
        return;
      }

      // 复制到目标目录
      await File(voicePath).copy(outputPath);

      // 创建历史记录
      final history = MediaGenerationHistory(
        requestId: const Uuid().v4(),
        prompt: promptController.text.trim(),
        negativePrompt: '',
        taskId: null,
        imageUrls: null,
        audioUrls: [outputPath], // audioUrls是List<String>类型
        voice: selectedVoice.name,
        refImageUrls: [],
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel!,
        modelType: LLModelType.tts,
        isSuccess: true,
      );

      // 保存到数据库
      await dbHelper.insertMediaGenerationHistory(history);

      // 清空输入
      if (mounted) {
        setState(() {
          promptController.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('语音生成成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 隐藏生成遮罩
      LoadingOverlay.hide();
      
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  // 删除任务记录
  Future<void> _deleteTask(MediaGenerationHistory task) async {
    await dbHelper.deleteMediaGenerationHistoryByRequestId(task.requestId);
    setState(() {});
  }

  @override
  Widget buildManagerScreen() => const MimeVoiceManager();

  Widget _buildTaskCard(MediaGenerationHistory task) {
    return Card(
      margin: EdgeInsets.all(5),
      child: ListTile(
        leading: Icon(
          Icons.music_note,
          size: ScreenHelper.isDesktop() ? 48 : 24,
        ),
        title: Text(
          "${CP_NAME_MAP[task.llmSpec.platform] ?? ''} ${task.llmSpec.model} ${task.voice}",
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          task.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12),
        ),
        // 语音生成任务完成且有结果
        trailing:
            task.isSuccess &&
                    task.audioUrls != null &&
                    task.audioUrls!.isNotEmpty
                ? IconButton(
                  onPressed: () {
                    // 显示音频播放对话框
                    ScreenHelper.isDesktop()
                        ? _desktopPlay(task)
                        : _mobilePlay(task);
                  },
                  icon: Icon(Icons.play_circle, size: 36, color: Colors.blue),
                )
                : Icon(Icons.hourglass_empty, size: 36),
        // 长按删除
        onLongPress: () {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('删除记录'),
                  content: Text('确定要删除此记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteTask(task);
                        Navigator.pop(context);
                      },
                      child: Text('确定'),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }

  _desktopPlay(MediaGenerationHistory task) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('语音预览'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AudioPlayerWidget(
                  audioUrl: task.audioUrls!.first,
                  autoPlay: true,
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('关闭'),
              ),
            ],
          ),
    );
  }

  _mobilePlay(MediaGenerationHistory task) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('语音预览', style: TextStyle(fontSize: 18)),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          unfocusHandle();
                        },
                        child: Text('关闭'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                  child: AudioPlayerWidget(
                    audioUrl: task.audioUrls!.first,
                    autoPlay: true,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  List<Widget> buildAppBarActions() {
    return [
      // 试听音色
      IconButton(
        icon: Icon(Icons.music_note_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VoiceTrialListeningPage()),
          );
        },
        tooltip: '试听音色',
      ),
      // 管理语音文件
      IconButton(
        icon: const Icon(Icons.photo_library_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => buildManagerScreen()),
          );
        },
      ),
      IconButton(
        onPressed: () {
          ScreenHelper.isDesktop()
              ? commonMarkdwonHintDialog(context, "$title使用说明", note)
              : commonMDHintModalBottomSheet(context, "$title使用说明", note);
        },
        icon: const Icon(Icons.info_outline),
      ),
    ];
  }
}
