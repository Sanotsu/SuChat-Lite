import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../common/components/loading_overlay.dart';
import '../../../common/components/toast_utils.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../models/brief_ai_tools/media_generation_history/media_generation_history.dart';
import '../../../services/qwen_tts_service.dart';
import '../../../services/voice_clone_service.dart';
import '../../../services/voice_generation_service.dart';

import '../common/media_generation_base.dart';

import 'mime_voice_manager.dart';
import 'audio_player_widget.dart';
import 'pages/voice_clone_page.dart';
import 'pages/voice_trial_listening_page.dart';

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
  - Qwen-TTS(最大输入 512 token)
  - CosyVoice(最大输入 2000 字符)
  - Sambert(最大输入 1 万字符)
- 文字越多耗时越久，**请勿在生成过程中退出**
- 生成的语音会保存在设备的以下目录:
  - /SuChatFiles/voice_generation
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
  modelChanged(CusBriefLLMSpec? model) async {
    if (model == null) return;
    setState(() {
      selectedModel = model;
    });

    // 2025-04-25 虽然不严谨，但暂时图省事这样写
    if (selectedModel?.modelType == LLModelType.tts) {
      final voices = await VoiceCloneService.getClonedVoices();

      List<AliyunVoiceType> clonedList =
          voices.map((e) {
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

      // 复制到目标目录
      await File(voicePath).copy(outputPath);

      // 2025-05-10 目前语音合成是直接得到结果，所以到这里就成功了，要创建历史记录
      history.audioUrls = [outputPath];
      history.isSuccess = true;
      history.isProcessing = false;
      history.isFailed = false;

      // 保存到数据库
      await dbHelper.insertMediaGenerationHistory(history);

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
      await dbHelper.insertMediaGenerationHistory(history);
    } finally {
      // 隐藏生成遮罩
      LoadingOverlay.hide();

      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  @override
  Widget buildManagerScreen() => const MimeVoiceManager();

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

  // Widget _buildTaskCard(MediaGenerationHistory task) {
  //   return Card(
  //     margin: EdgeInsets.all(5),
  //     child: ListTile(
  //       dense: true,
  //       leading: Icon(
  //         Icons.music_note,
  //         size: ScreenHelper.isDesktop() ? 48 : 24,
  //       ),
  //       title: Row(
  //         children: [
  //           Expanded(
  //             child: Text(
  //               "${CP_NAME_MAP[task.llmSpec.platform] ?? ''} ${task.llmSpec.model}",
  //               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  //               maxLines: 2,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ),
  //           buildTaskStatusIndicator(task),
  //         ],
  //       ),
  //       subtitle: SizedBox(
  //         height: 56,
  //         child: Text(
  //           "${task.gmtCreate}\n${task.prompt}",
  //           maxLines: 3,
  //           overflow: TextOverflow.ellipsis,
  //           style: TextStyle(fontSize: 12),
  //         ),
  //       ),
  //       // 点击播放
  //       onTap: () {
  //         if (task.isSuccess == true &&
  //             task.audioUrls != null &&
  //             task.audioUrls!.isNotEmpty) {
  //           // 显示音频播放对话框
  //           ScreenHelper.isDesktop() ? _desktopPlay(task) : _mobilePlay(task);
  //         } else if (task.isFailed == true) {
  //           if (task.otherParams != null) {
  //             var otherParams = jsonDecode(task.otherParams!);

  //             if (otherParams['errorMsg'] != null) {
  //               commonExceptionDialog(
  //                 context,
  //                 "AI语音生成失败",
  //                 otherParams['errorMsg'],
  //               );
  //             } else {
  //               commonExceptionDialog(context, "AI语音生成失败", '具体错误未知，可删除任务后重新生成');
  //             }
  //           }
  //         }
  //       },
  //       // 长按删除
  //       onLongPress: () {
  //         showDialog(
  //           context: context,
  //           builder:
  //               (context) => AlertDialog(
  //                 title: Text('删除记录'),
  //                 content: Text('确定要删除此记录吗？'),
  //                 actions: [
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: Text('取消'),
  //                   ),
  //                   TextButton(
  //                     onPressed: () async {
  //                       await dbHelper.deleteMediaGenerationHistoryByRequestId(
  //                         task.requestId,
  //                       );
  //                       setState(() {});
  //                       if (!context.mounted) return;
  //                       Navigator.pop(context);
  //                     },
  //                     child: Text('确定'),
  //                   ),
  //                 ],
  //               ),
  //         );
  //       },
  //     ),
  //   );
  // }

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
      itemBuilder:
          (BuildContext context) => <PopupMenuItem<String>>[
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
