import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/utils/tools.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../models/brief_ai_tools/media_generation_history/media_generation_history.dart';
import '../../../services/image_generation_service.dart';
import '../../../views/brief_ai_assistant/common/media_generation_base.dart';
import 'mime_image_manager.dart';
import '../../../common/components/loading_overlay.dart';

class BriefImageScreen extends MediaGenerationBase {
  const BriefImageScreen({super.key});

  @override
  State<BriefImageScreen> createState() => _BriefImageScreenState();
}

class _BriefImageScreenState
    extends MediaGenerationBaseState<BriefImageScreen> {
  final List<String> _generatedImages = [];

  // 根据模型切换后才更新对应模型支持的尺寸
  List<CusLabel> _imageSizeOptions = [
    CusLabel(cnLabel: "1:1", value: "1024x1024"),
  ];

  late CusLabel _selectedImageSize;

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
  - /SuChatFiles/image_generation
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
        onChanged:
            isGenerating
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
  modelChanged(CusBriefLLMSpec? model) {
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
    referenceImage = null;
    _selectedImageSize = _imageSizeOptions.first;
    setState(() {});
  }

  @override
  Widget buildGeneratedList() {
    if (_generatedImages.isEmpty) {
      return Center(child: Text('暂无生成的图片', style: TextStyle(fontSize: 16)));
    }

    /// 图片展示
    return Column(
      children: [
        /// 文生图的结果
        if (_generatedImages.isNotEmpty)
          ...buildImageResultGrid(
            _generatedImages,
            "${selectedModel?.platform.name}_${selectedModel?.name}",
          ),
      ],
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
        refImageUrls: [],
        gmtCreate: DateTime.now(),
        llmSpec: selectedModel!,
        modelType: selectedModel!.modelType,
      );

      final requestId = await dbHelper.insertMediaGenerationHistory(history);

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

      // 保存返回的网络图片到本地
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

      // 更新UI(这里使用网络地址或本地地址没差，毕竟历史记录在其他页面，这里只有当前页面还在时才有图片展示)
      if (!mounted) return;
      setState(() {
        _generatedImages.addAll(newUrls);
      });

      // 更新数据库历史记录。如果是阿里云平台，则需要保存任务ID和已完成的标识
      await dbHelper.updateMediaGenerationHistoryByRequestId(requestId, {
        'taskId':
            selectedModel?.platform == ApiPlatform.aliyun
                ? response.output?.taskId
                : null,
        'isSuccess': 1,
        'imageUrls': _generatedImages.join(','),
      });
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "AI图片生成失败: $e");
      rethrow;
    } finally {
      // 隐藏生成遮罩
      LoadingOverlay.hide();

      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  @override
  // Widget buildManagerScreen() => const ImageManagerScreen();
  // 2025-02-26 ??? 多次测试，在生成图片并保存后，
  // 使用photo_manager搜索定位到指定AI生成图片文件夹，并看不到所有的图片。
  // 可能实际有10张，photo_manager得到6张，原因还在探索。
  // 暂时使用遍历文件夹中的File List，通过mime库区分媒体资源内容，然后简单预览
  // 但是媒体资源的信息就差很多，只能得到File的信息而不是原始媒体资源的信息
  Widget buildManagerScreen() => const MimeImageManager();

  @override
  void initState() {
    super.initState();

    _selectedImageSize = _imageSizeOptions.first;

    _checkUnfinishedTasks();
  }

  // 检查未完成的任务
  // 2025-02-20 和视频生成中不一样，图片生成目前就阿里云的通义万相-文生图V2版需要任务查询，其他直接返回的
  // 耗时不会特别长，所以这里调用轮询
  Future<void> _checkUnfinishedTasks() async {
    // 查询未完成的任务
    final all = await dbHelper.queryMediaGenerationHistory(
      modelTypes: [LLModelType.image, LLModelType.tti, LLModelType.iti],
    );

    // 过滤出未完成的任务
    final unfinishedTasks = all.where((e) => e.isProcessing == true).toList();

    // 遍历未完成的任务
    for (final task in unfinishedTasks) {
      if (task.taskId != null) {
        try {
          // 2025-05-08 注意，这里是自定义的图片生成结果
          // 如果轮询过程中有结果了，直接在result中取值
          // 如果还在处理中，则不会返回；
          // 如果报错或者失败了，会有code和message
          final response = await ImageGenerationService.pollTaskStatus(
            modelList.firstWhere(
              (model) => model.platform == task.llmSpec.platform,
            ),
            task.taskId!,
          );

          if (response.code != null || response.message != null) {
            await dbHelper.updateMediaGenerationHistoryByRequestId(
              task.requestId,
              {'isFailed': 1},
            );
          } else if (response.results.isNotEmpty) {
            if (!mounted) return;

            // 保存返回的网络图片到本地
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

            // 更新UI(这里使用网络地址或本地地址没差，毕竟历史记录在其他页面，这里只有当前页面还在时才有图片展示)
            if (!mounted) return;
            setState(() {
              _generatedImages.addAll(newUrls);
            });

            await dbHelper
                .updateMediaGenerationHistoryByRequestId(task.requestId, {
                  'isSuccess': 1,
                  'isProcessing': 0,
                  'imageUrls': _generatedImages.join(','),
                });
          }
        } catch (e) {
          debugPrint('检查任务状态失败: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('检查任务状态失败: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  /// 构建生成的图片区域
  List<Widget> buildImageResultGrid(List<String> urls, String? prefix) {
    return [
      const Divider(),

      // 文生图结果提示行
      Padding(
        padding: EdgeInsets.all(5),
        child: Text(
          "生成的图片(点击查看、长按保存)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // 图片展示区域
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(5),
                child: buildNetworkImageViewGrid(
                  context,
                  urls,
                  crossAxisCount: ScreenHelper.isDesktop() ? 3 : 2,
                  prefix: prefix,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
