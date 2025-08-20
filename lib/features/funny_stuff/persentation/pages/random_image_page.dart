import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../core/network/url_utils.dart';
import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/get_dir.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/datasources/index.dart';

class RandomImagePage extends StatefulWidget {
  const RandomImagePage({super.key});

  @override
  State<RandomImagePage> createState() => _RandomImagePageState();
}

class _RandomImagePageState extends State<RandomImagePage> {
  late PageController _pageController;
  // 图片列表
  List<String> imageList = [];
  // 当前显示的图片列表的索引
  int _currentIndex = 0;
  bool _isLoading = false;

  // 图片分类
  List<CusLabel> categories = [
    CusLabel(cnLabel: "美女", value: "beauty"),
    CusLabel(cnLabel: "其他", value: "other"),
    CusLabel(cnLabel: "附加", value: "json"),
  ];
  // 当前被选中的分类索引(默认选中第一个，全部)
  int _selectedIndex = 0;
  // 被选中的分类
  late CusLabel selectedNewsCategory;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    selectedNewsCategory = categories[_selectedIndex];

    _addNewImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<String> getImageUrl() async {
    var category = selectedNewsCategory.value as String;

    var orignalUrl = category == "beauty"
        ? beautyImages[Random().nextInt(beautyImages.length)]
        : (category == "other"
              ? otherImages[Random().nextInt(otherImages.length)]
              : jsonImages[Random().nextInt(jsonImages.length)]);

    try {
      // 如果是json，需要先请求，然后获取url
      if (category == "json") {
        var respData = await HttpUtils.get(
          path: orignalUrl,
          responseType:
              (orignalUrl.contains("api/bilibili_start_imag") ||
                  orignalUrl.contains("api/picture") ||
                  orignalUrl.contains("api/bizhi"))
              ? CusRespType.plain
              : CusRespType.json,
          showLoading: true,
          showErrorMessage: false,
        );

        if (orignalUrl.contains("api/loveanimer")) {
          if (respData.runtimeType == String) {
            respData = json.decode(respData);
          }

          orignalUrl = (respData["data"] as List).first["url"];
        } else if (orignalUrl.contains("api/bilibili_start_imag") ||
            orignalUrl.contains("api/picture")) {
          orignalUrl = respData.toString();
        } else if (orignalUrl.contains("api/bizhi")) {
          orignalUrl = respData
              .toString()
              .replaceAll('±img=', '')
              .replaceAll('±', '');
        } else {
          orignalUrl = respData["text"];
        }
      }

      var time = DateTime.now().millisecondsSinceEpoch;

      // 有些请求带参数，需要用&连接，有些请求不带参数，需要用?连接
      // url虽然每次请求应该是返回不一样的图片，但是不带时间戳会被CacheNetworkImage缓存，导致每次都是同一张图片
      return orignalUrl.contains("?")
          ? "$orignalUrl&random=$time"
          : "$orignalUrl?random=$time";
    } catch (e) {
      ToastUtils.showError('获取图片失败:${e.toString()}');
      // print("获取图片失败:${e.toString()}");
      rethrow;
    }
  }

  // 添加新图片
  void _addNewImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool isAvailable = await UrlUtils.isUrlAvailable('https://api.suyanw.cn');

      if (!isAvailable && mounted) {
        ToastUtils.showError('站点不可用，请稍后再试');

        setState(() {
          _isLoading = false;
        });
        return;
      }

      final newImageUrl = await getImageUrl();
      if (!mounted) return;
      setState(() {
        imageList.add(newImageUrl);
        _currentIndex = imageList.length - 1;
      });

      if (imageList.length > 1) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      ToastUtils.showError('获取图片失败:${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //  处理搜索
  void _handleSearch() {
    _addNewImage();
  }

  Future<File?> getCachedImageFile(String imageUrl) async {
    final cacheManager = DefaultCacheManager();
    final fileInfo = await cacheManager.getFileFromCache(imageUrl);
    return fileInfo?.file;
  }

  // 因为图片url每次都是随机新的图片，也就是说虽然预览和保存的url是同一个，但保存下来和预览的是不一样的图片
  // 所以保存时，是直接把CacheNetworkImage缓存的图片复制到指定保存的位置去
  Future<void> saveCurrentImage() async {
    if (imageList.isEmpty) return;

    final currentImageUrl = imageList[_currentIndex];
    final cachedFile = await getCachedImageFile(currentImageUrl);

    if (cachedFile == null || !await cachedFile.exists()) {
      ToastUtils.showError("图片缓存不存在，保存失败");
      return;
    }

    final saveDir = await getDioDownloadDir();
    final savePath = '${saveDir.path}/随机图片_${fileTs(DateTime.now())}.jpg';

    try {
      await cachedFile.copy(savePath);
      ToastUtils.showToast(
        '图片已保存到: $savePath',
        align: Alignment.bottomCenter,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      ToastUtils.showError('保存失败: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('随机图片')),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: saveCurrentImage,
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && imageList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imageList.isEmpty) {
      return const Center(child: Text('没有找到图片'));
    }

    return Column(
      children: [
        buildCategoryListArea(),
        Text(imageList[_currentIndex].split('?').first),
        Expanded(child: buildImageView()),
        SizedBox(height: 8),
      ],
    );
  }

  Row buildCategoryListArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: buildDropdownButton2<CusLabel>(
            value: categories[_selectedIndex],
            items: categories,
            labelSize: 15,
            hintLabel: "选择分类",
            onChanged: (value) async {
              setState(() {
                _selectedIndex = categories.indexOf(value!);
                selectedNewsCategory = value;
              });
              _handleSearch();
            },
            itemToString: (e) => (e as CusLabel).cnLabel,
          ),
        ),
        Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              '${_currentIndex + 1}/${imageList.length}',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _addNewImage),
      ],
    );
  }

  PhotoViewGallery buildImageView() {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(imageList[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 4,
          heroAttributes: PhotoViewHeroAttributes(tag: imageList[index]),
        );
      },
      itemCount: imageList.length,
      loadingBuilder: (context, event) => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value:
                event?.cumulativeBytesLoaded.toDouble() ??
                0 / (event?.expectedTotalBytes?.toDouble() ?? 1),
          ),
        ),
      ),
      backgroundDecoration: BoxDecoration(color: Theme.of(context).canvasColor),
      pageController: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
