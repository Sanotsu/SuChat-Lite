import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../core/utils/get_dir.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../common/entities/media_generation_history.dart';
import '../../common/pages/media_generation_base.dart';
import '../data/repositories/qwen_tts_service.dart';
import '../data/repositories/voice_clone_service.dart';
import '../data/repositories/voice_generation_service.dart';
import 'pages/mime_voice_manager_page.dart';
import 'pages/voice_clone_page.dart';
import 'pages/voice_trial_listening_page.dart';

class GenVoicePage extends MediaGenerationBase {
  const GenVoicePage({super.key});

  @override
  State<GenVoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends MediaGenerationBaseState<GenVoicePage> {
  @override
  List<LLModelType> get mediaTypes => [LLModelType.tts];

  @override
  String get title => '语音合成';

  @override
  String get note => '''
- 目前只支持**阿里云**平台的语音合成服务
- 先选择平台模型和音色，再输入要合成的文本
- 支持:
  - Qwen-TTS(最大输入 512 token)
  - CosyVoice(最大输入 2000 字符)
  - Sambert(最大输入 1 万字符)
- 文字越多耗时越久，**请勿在生成过程中退出**
- 生成的语音会保存在设备的以下目录:
  - /SuChatFiles/AI_GEN/voices
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
        onChanged: isGenerating
            ? null
            : (value) {
                setState(() => selectedVoice = value!);
              },
        itemToString: (e) => (e as AliyunVoiceType).name,
      ),
    );
  }

  @override
  modelChanged(CusLLMSpec? model) async {
    if (model == null) return;
    setState(() {
      selectedModel = model;
    });

    // 2025-04-25 虽然不严谨，但暂时图省事这样写
    if (selectedModel?.modelType == LLModelType.tts) {
      final voices = await VoiceCloneService.getClonedVoices();

      List<AliyunVoiceType> clonedList = voices.map((e) {
        // 理论上api查询结果中都有这个id的

        // 作为name时不需要前面的cosyvoice-固定内容
        // var name = e.voiceId!.substring(10);
        var tempList = e.voiceId!.split("-");
        var name = "${tempList[1]}-${tempList[2]}";
        return AliyunVoiceType(name, e.voiceId!, "", "", "", "");
      }).toList();

      if (selectedModel?.model == "cosyvoice-v1") {
        voiceOptions =
            VoiceGenerationService.getV1AvailableVoices() +
            clonedList.where((e) => e.id.startsWith("cosyvoice-v1")).toList();
      } else if (selectedModel?.model == "cosyvoice-v2") {
        voiceOptions =
            VoiceGenerationService.getV2AvailableVoices() +
            clonedList.where((e) => e.id.startsWith("cosyvoice-v2")).toList();
      } else if (selectedModel?.model == "sambert") {
        voiceOptions = VoiceGenerationService.getSambertVoices();
      } else if (selectedModel?.model != null &&
          selectedModel!.model.contains('qwen-tts')) {
        voiceOptions = VoiceGenerationService.getQwenTTSVoices();
      }

      selectedVoice = voiceOptions.first;
      // 刷新状态
      setState(() {});
    }
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
    LoadingOverlay.showVoiceGeneration(
      context,
      onCancel: () {
        // 取消生成
        setState(() => isGenerating = false);
      },
    );

    // 2025-05-10 目前语音合成是直接得到结果，成功失败都要存入数据库
    // 先创建一个类实例，实际用到时更新属性
    final history = MediaGenerationHistory(
      requestId: const Uuid().v4(),
      prompt: promptController.text.trim(),
      negativePrompt: '',
      taskId: null,
      imageUrls: null,
      audioUrls: null,
      voice: selectedVoice.name,
      refImageUrls: null,
      gmtCreate: DateTime.now(),
      llmSpec: selectedModel!,
      modelType: LLModelType.tts,
      isProcessing: true,
      isSuccess: false,
      isFailed: false,
    );

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

      // 复制到目标目录(？？？生成时是放在TemporaryDir，这里可以考虑保存db成功之后删除)
      await File(voicePath).copy(outputPath);

      // 2025-05-10 目前语音合成是直接得到结果，所以到这里就成功了，要创建历史记录
      history.audioUrls = [outputPath];
      history.isSuccess = true;
      history.isProcessing = false;
      history.isFailed = false;

      // 保存到数据库
      await dbHelper.saveMediaGenerationHistory(history);

      // 清空输入
      if (mounted) {
        setState(() {
          promptController.clear();
        });

        ToastUtils.showSuccess('语音生成成功');
      }
    } catch (e) {
      ToastUtils.showError('生成失败: $e', duration: Duration(seconds: 5));
      // 生成失败，也要创建历史记录
      history.isSuccess = false;
      history.isProcessing = false;
      history.isFailed = true;
      history.otherParams = jsonEncode({"errorMsg": e.toString()});

      // 保存到数据库
      await dbHelper.saveMediaGenerationHistory(history);
    } finally {
      // 隐藏生成遮罩
      LoadingOverlay.hide();

      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  @override
  Widget buildManagerPage() => const MimeVoiceManager();

  // 构建任务卡片(音频、视频、图片都相似结构)
  Widget _buildTaskCard(MediaGenerationHistory task) {
    Widget mediaPreview = Icon(Icons.music_note, size: 36);
    return buildMediaTaskCard(
      task: task,
      mediaPreview: mediaPreview,
      // 点击播放
      onTap: () {
        if (task.isSuccess == true &&
            task.audioUrls != null &&
            task.audioUrls!.isNotEmpty) {
          // 显示音频播放对话框
          ScreenHelper.isDesktop() ? _desktopPlay(task) : _mobilePlay(task);
        } else if (task.isFailed == true) {
          if (task.otherParams != null) {
            var otherParams = jsonDecode(task.otherParams!);

            if (otherParams['errorMsg'] != null) {
              commonExceptionDialog(
                context,
                "AI语音生成失败",
                otherParams['errorMsg'],
              );
            } else {
              commonExceptionDialog(context, "AI语音生成失败", '具体错误未知，可删除任务后重新生成');
            }
          }
        }
      },
      onLongPress: () async {
        final result = await showDeleteTaskConfirmDialog(context, "音频");

        if (result == true) {
          await dbHelper.deleteMediaGenerationHistoryByRequestId(
            task.requestId,
          );
        }
      },
    );
  }

  void _desktopPlay(MediaGenerationHistory task) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text('语音预览'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(child: Text(task.prompt)),
                ),
              ),
              AudioPlayerWidget(
                audioUrl: task.audioUrls!.first,
                autoPlay: true,
              ),
            ],
          ),
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

  void _mobilePlay(MediaGenerationHistory task) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) => Container(
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(child: Text(task.prompt)),
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

  // 弹窗菜单按钮
  Widget buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_sharp),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'trial_listening') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VoiceTrialListeningPage()),
          );
        } else if (value == 'voice_clone') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VoiceClonePage()),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        buildCusPopupMenuItem(
          context,
          "trial_listening",
          "试听音色",
          Icons.music_note_outlined,
        ),
        buildCusPopupMenuItem(
          context,
          "voice_clone",
          "声音复刻",
          Icons.record_voice_over,
        ),
      ],
    );
  }

  @override
  List<Widget> buildAppBarActions() {
    return [
      // 声音复刻 和 试听音色
      buildPopupMenuButton(),
      // 管理语音文件
      IconButton(
        icon: const Icon(Icons.photo_library_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => buildManagerPage()),
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
