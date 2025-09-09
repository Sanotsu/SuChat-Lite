import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/get_dir.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../common/entities/media_generation_history.dart';
import '../../common/pages/media_generation_base.dart';
import '../data/models/image_generation_response.dart';
import '../data/repositories/image_generation_service.dart';
import 'pages/mime_image_manager_page.dart';

class GenImagePage extends MediaGenerationBase {
  const GenImagePage({super.key});

  @override
  State<GenImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends MediaGenerationBaseState<GenImagePage> {
  // 所有的图片生成任务
  final List<MediaGenerationHistory> _allTasks = [];

  // 根据模型切换后才更新对应模型支持的尺寸
  List<CusLabel> _imageSizeOptions = [
    CusLabel(cnLabel: "1:1", value: "1024x1024"),
  ];

  late CusLabel _selectedImageSize;

  /// 图片任务展示
  bool isGrid = false;

  @override
  List<LLModelType> get mediaTypes => [
    LLModelType.image,
    LLModelType.tti,
    LLModelType.iti,
  ];

  @override
  String get title => 'AI 绘图';

  @override
  String get note => '''
- 目前只支持的以下平台的部分模型:
  - **阿里云**"通义万相-文生图V2版"、Flux系列
  - **硅基流动**文生图模型
  - **智谱AI**的文生图模型
- 先选择平台模型和图片比例，再输入提示词
  - 智谱支持的尺寸与众不同，故用近似比例
- 文生图耗时较长，**请勿在生成过程中退出**
- 默认一次生成1张图片
- 生成的图片会保存在设备的以下目录:
  - /SuChatFiles/AI_GEN/images
''';

  @override
  Widget buildMediaOptions() {
    return SizedBox(
      width: 90,
      child: buildDropdownButton2<CusLabel?>(
        height: 48,
        value: _selectedImageSize,
        items: _imageSizeOptions,
        hintLabel: "选择类型",
        onChanged: isGenerating
            ? null
            : (value) {
                setState(() => _selectedImageSize = value!);
              },
        itemToString: (e) => (e as CusLabel).cnLabel,
      ),
    );
  }

  // 当生图的模型切换后，更新可选的尺寸列表
  // 注意，有些是x，有些是*
  @override
  modelChanged(CusLLMSpec? model) {
    if (model == null) return;

    setState(() {
      selectedModel = model;
    });

    if (model.platform == ApiPlatform.siliconCloud) {
      _imageSizeOptions = [
        CusLabel(cnLabel: "1:1", value: "1024x1024"),
        CusLabel(cnLabel: "1:2", value: "720x1440"),
        CusLabel(cnLabel: "3:4(大)", value: "960x1280"),
        CusLabel(cnLabel: "3:4(小)", value: "768x1024"),
        CusLabel(cnLabel: "9:16", value: "720x1280"),
        CusLabel(cnLabel: "16:9", value: "1280x720"),
      ];
    }

    if (model.platform == ApiPlatform.zhipu) {
      _imageSizeOptions = [
        CusLabel(cnLabel: "1:1", value: "1024x1024"),
        CusLabel(cnLabel: "4:7", value: "768x1344"),
        CusLabel(cnLabel: "3:4", value: "864x1152"),
        CusLabel(cnLabel: "7:4", value: "1344x768"),
        CusLabel(cnLabel: "4:3", value: "1152x864"),
        CusLabel(cnLabel: "2:1", value: "1440x720"),
        CusLabel(cnLabel: "1:2", value: "720x1440"),
      ];
    }

    if (model.platform == ApiPlatform.aliyun) {
      // 2025-08-20 阿里云新的“通义千问-文生图”的尺寸和之前通义万相的支持列表不一样
      // https://bailian.console.aliyun.com/?tab=api#/api/?type=model&url=2975126
      if (model.model.contains("qwen-image")) {
        _imageSizeOptions = [
          CusLabel(cnLabel: "1:1", value: "1328*1328"),
          CusLabel(cnLabel: "4:3", value: "1472*1140"),
          CusLabel(cnLabel: "3:4", value: "1140*1472"),
          CusLabel(cnLabel: "16:9", value: "1664*928"),
          CusLabel(cnLabel: "9:16", value: "928*1664"),
        ];
      } else {
        // flux只有6中默认尺寸，但通义万相-文生图V2宽高边长的像素范围为[512, 1440]的任意尺寸，最大200w像素
        // 所以默认使用flux的尺寸就好
        // if (model.model.contains("flux")) {
        _imageSizeOptions = [
          CusLabel(cnLabel: "1:1", value: "1024*1024"),
          CusLabel(cnLabel: "1:2", value: "512*1024"),
          CusLabel(cnLabel: "3:2", value: "768*512"),
          CusLabel(cnLabel: "3:4", value: "768*1024"),
          CusLabel(cnLabel: "16:9", value: "1024*576"),
          CusLabel(cnLabel: "9:16", value: "576*1024"),
        ];
        // }
      }
    }
    referenceImage = null;
    _selectedImageSize = _imageSizeOptions.first;
    setState(() {});
  }

  @override
  Widget buildGeneratedList() {
    if (_allTasks.isEmpty) {
      return Center(child: Text('暂无生成的图片', style: TextStyle(fontSize: 16)));
    }

    return Column(
      children: [
        Divider(height: 5),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "图片生成任务",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _checkUnfinishedTasks(),
                icon: Icon(Icons.refresh, color: Colors.blue),
              ),
              IconButton(
                onPressed: () => setState(() => isGrid = !isGrid),
                icon: Icon(
                  isGrid ? Icons.list : Icons.grid_view,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 5),
        Expanded(child: _buildTaskList(isGrid)),
      ],
    );
  }

  // 构建任务列表
  Widget _buildTaskList(bool isGrid) {
    //
    return isGrid
        ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
            ),
            itemCount: _allTasks.length,
            itemBuilder: (context, index) {
              var task = _allTasks[index];
              return _buildImageTaskCard(task, isGrid: isGrid);
            },
          )
        : ListView.builder(
            itemCount: _allTasks.length,
            itemBuilder: (context, index) {
              var task = _allTasks[index];
              return _buildImageTaskCard(task, isGrid: isGrid);
            },
          );
  }

  // 构建图片任务卡片
  Widget _buildImageTaskCard(
    MediaGenerationHistory task, {
    bool isGrid = false,
  }) {
    // 图片预览区域
    Widget buildImagePreview() {
      if (task.isSuccess == true &&
          task.imageUrls != null &&
          task.imageUrls!.isNotEmpty) {
        // 修复：imageUrls可能是一个用逗号分隔的字符串，我们需要先检查它是否是字符串
        String imagePath = task.imageUrls!.first;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 80,
            width: 80,
            // child: buildImageGridTile(context, imagePath, fit: BoxFit.cover),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
              },
            ),
          ),
        );
      } else {
        return Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              task.isProcessing == true ? Icons.hourglass_empty : Icons.image,
              size: 40,
              color: Colors.grey,
            ),
          ),
        );
      }
    }

    return buildMediaTaskCard(
      task: task,
      isGrid: isGrid,
      mediaPreview: buildImagePreview(),
      onTap: () {
        if (task.isSuccess == true &&
            task.imageUrls != null &&
            task.imageUrls!.isNotEmpty) {
          // 查看大图，此时一定有生产的图片列表(job预览时是单个，但是大图预览时，可能是一次性有多个图片)
          _viewFullImage(task);
        } else if (task.isProcessing == true) {
          // 检查任务状态
          _checkTaskStatus(task);
        } else if (task.isFailed == true) {
          if (task.otherParams != null) {
            var otherParams = jsonDecode(task.otherParams!);

            if (otherParams['output'] != null) {
              AliyunWanxV2Output output = AliyunWanxV2Output.fromJson(
                otherParams['output'],
              );

              commonExceptionDialog(
                context,
                "AI图片生成失败",
                "任务状态: ${output.taskStatus}\n错误代码\n${output.code}\n错误信息\n${output.message}",
              );
            } else if (otherParams['errorMsg'] != null) {
              commonExceptionDialog(
                context,
                "AI图片生成失败",
                otherParams['errorMsg'],
              );
            }
          }
        }
      },
      onLongPress: () async {
        final result = await showDeleteTaskConfirmDialog(context, "图片");

        if (result == true) {
          await dbHelper.deleteMediaGenerationHistoryByRequestId(
            task.requestId,
          );
          if (!mounted) return;
          await _queryAllTasks();
        }
      },
    );
  }

  @override
  Future<void> generate() async {
    if (!checkGeneratePrerequisites()) return;

    setState(() => isGenerating = true);

    // 显示生成遮罩
    LoadingOverlay.showImageGeneration(
      context,
      onCancel: () {
        // 取消生成
        setState(() => isGenerating = false);
      },
    );

    try {
      // 创建历史记录
      final history = MediaGenerationHistory(
        requestId: const Uuid().v4(),
        prompt: promptController.text.trim(),
        negativePrompt: '',
        taskId: null,
        imageUrls: null,
        refImageUrls: referenceImage?.path != null
            ? [referenceImage!.path]
            : null,
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel!,
        modelType: selectedModel!.modelType,
      );

      final requestId = await dbHelper.saveMediaGenerationHistory(history);

      try {
        final response = await ImageGenerationService.generateImage(
          selectedModel!,
          promptController.text.trim(),
          n: 1,
          size: _selectedImageSize.value,
          refImage:
              (selectedModel?.modelType == LLModelType.image ||
                  selectedModel?.modelType == LLModelType.iti)
              ? referenceImage
              : null,
          // 必须传入requestId，否则阿里云平台的job没有无法保存到数据库，那这里的查询未完成job永远都是0
          requestId: requestId,
        );

        if (!mounted) return;
        // 如果用户没有取消掉遮罩，那么到这里就是已经是获得了图片的响应，保存返回的网络图片到本地
        var imageUrls = response.results.map((r) => r.url).toList();
        List<String> newUrls = [];
        for (final url in imageUrls) {
          var localPath = await saveImageToLocal(
            url,
            dlDir: await getImageGenDir(),
            showSaveHint: false,
          );

          if (localPath != null) {
            newUrls.add(localPath);
          }
        }

        // 2025-05-10 如果是阿里云平台，在job轮询时就已经更新了数据库，这里不必重复更新
        // 所以这里只处理非阿里云平台的情况
        // ？？？注意，其他平台生成图片报错还没准确处理
        if (selectedModel?.platform != ApiPlatform.aliyun) {
          await dbHelper.updateMediaGenerationHistoryByRequestId(requestId, {
            'taskId': selectedModel?.platform == ApiPlatform.aliyun
                ? response.output?.taskId
                : null,
            'isSuccess': 1,
            'isProcessing': 0,
            'taskStatus': response.output?.taskStatus,
            // 2025-05-09 注意在MediaGenerationHistory类的toMap方法中，imageUrls是分号分割的
            'imageUrls': newUrls.join(';'),
            'prompt': promptController.text.trim(),
          });
        }
      } catch (e) {
        // 2025-05-10 这里统一处理错误，直接报错的会有弹窗，但没有存入数据库
        // 阿里云的如果能提交job，那么job生成出错在消息体内，也是正常完成；
        // 如果提交job就失败(比如提示词就违规)，那就和硅基流动和智谱一样，会直接http层面的抛错
        await dbHelper.updateMediaGenerationHistoryByRequestId(requestId, {
          'taskId': null,
          'isSuccess': 0,
          'isProcessing': 0,
          'isFailed': 1,
          'taskStatus': "FAILED",
          'imageUrls': null,
          "otherParams": jsonEncode({"errorMsg": e.toString()}),
        });
      }
      // 提交新任务之后，重新查询所有任务并更新UI
      await _queryAllTasks();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "AI图片生成失败: $e");
    } finally {
      // 隐藏生成遮罩
      LoadingOverlay.hide();

      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  @override
  // 2025-02-26 ??? 多次测试，在生成图片并保存后，
  // 使用photo_manager搜索定位到指定AI生成图片文件夹，并看不到所有的图片。
  // 可能实际有10张，photo_manager得到6张，原因还在探索。
  // 暂时使用遍历文件夹中的File List，通过mime库区分媒体资源内容，然后简单预览
  // 但是媒体资源的信息就差很多，只能得到File的信息而不是原始媒体资源的信息
  // 2025-05-23 photo_manager 不支持桌面获取，相关页面也删除，使用MIME版本
  Widget buildManagerPage() => const MimeImageManagerPage();

  @override
  void initState() {
    super.initState();

    _selectedImageSize = _imageSizeOptions.first;

    _checkUnfinishedTasks();
  }

  // 查看大图
  void _viewFullImage(MediaGenerationHistory task) {
    var prompt = task.prompt;

    // ？？？2025-05-10 这里暂时没有针对一次性生成多个图片时，每个图片单独显示实际提示词，而是放在一起
    if (task.llmSpec.model.contains("wanx") && task.otherParams != null) {
      var otherParams = jsonDecode(task.otherParams!);

      AliyunWanxV2Output output = AliyunWanxV2Output.fromJson(
        otherParams['output'],
      );

      var actualPrompt =
          output.results?.map((e) => e.actualPrompt ?? '').join('\n') ?? '';

      prompt += '\n$actualPrompt';
    }

    Widget promptCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('提示词', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prompt));
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
                // 最大高度150，超过则滚动
                constraints: BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: SelectableText(
                    prompt,
                    textAlign: TextAlign.justify, // 双端对齐
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        insetPadding: ScreenHelper.isMobile() ? EdgeInsets.all(8) : null,
        child: Container(
          width: 800, // 桌面端限制宽度，手机端一般都达不到800的
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('图片预览(共${task.imageUrls?.length}张)'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Container(
                height: 160,
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    buildImageViewCarouselSlider(
                      task.imageUrls!,
                      aspectRatio: 1,
                    ),
                    SizedBox(width: 10),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.gmtCreate.toString(),
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              CP_NAME_MAP[task.llmSpec.platform] ?? '',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              task.llmSpec.model,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(task.imageUrls?.join(';') ?? ''),
                ),
              ),

              promptCard,
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // 查询所有图片生成任务
  Future<void> _queryAllTasks() async {
    final all = await dbHelper.queryMediaGenerationHistory(
      modelTypes: [LLModelType.image, LLModelType.tti, LLModelType.iti],
    );

    if (!mounted) return;
    setState(() {
      _allTasks.clear();
      _allTasks.addAll(all);
    });
  }

  // 检查未完成的任务
  Future<void> _checkUnfinishedTasks() async {
    try {
      // 查询所有图片生成任务
      await _queryAllTasks();

      // 过滤出未完成的任务
      final unfinishedTasks = _allTasks
          .where((e) => e.isProcessing == true)
          .toList();

      if (unfinishedTasks.isEmpty) return;

      // 状态等待中的任务需要检查
      for (final task in unfinishedTasks) {
        if (task.taskId != null) {
          try {
            // 检查任务状态
            _checkTaskStatus(task);
          } catch (e) {
            debugPrint('检查任务状态失败: $e');
            ToastUtils.showError(
              '检查任务状态失败: $e',
              duration: Duration(seconds: 5),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('查询未完成任务失败: $e');
      ToastUtils.showError('查询未完成任务失败: $e');
    }
  }

  // 检查任务状态
  Future<void> _checkTaskStatus(MediaGenerationHistory task) async {
    if (task.taskId == null) return;

    try {
      // 显示加载状态
      LoadingOverlay.show(context, title: '正在检查任务状态...');

      // 在service中有更新任务状态到数据库，所以这里直接轮询结果就好
      final response = await ImageGenerationService.pollTaskStatus(
        task.requestId,
        modelList.firstWhere(
          (model) => model.platform == task.llmSpec.platform,
        ),
        task.taskId!,
      );

      if (response.results.isNotEmpty) {
        ToastUtils.showSuccess('图片生成任务已完成');
      }

      // 刷新任务列表
      await _queryAllTasks();
    } catch (e) {
      debugPrint('检查图片生成任务状态失败: $e');
      ToastUtils.showError('检查图片生成任务状态失败: $e');
    } finally {
      // 隐藏加载状态
      LoadingOverlay.hide();
    }
  }
}
