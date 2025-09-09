import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/get_dir.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';

/// 有几个API返回的新闻报纸的图片，直接用这个显示
class NewsImageGallery extends StatefulWidget {
  final Map<String, String> imageUrls;
  final String? title;

  const NewsImageGallery({super.key, required this.imageUrls, this.title});

  @override
  State<NewsImageGallery> createState() => _NewsImageGalleryState();
}

class _NewsImageGalleryState extends State<NewsImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageList = widget.imageUrls.entries.toList();

    if (imageList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title ?? '新闻图片')),
        body: Center(child: Text('没有找到图片')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '新闻图片'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${imageList.length}',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageList[index].value),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(
              tag: imageList[index].value,
            ),
          );
        },
        itemCount: imageList.length,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20.0.w,
            height: 20.0.h,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
            ),
          ),
        ),
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
        ),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 保存图片的逻辑
          final currentImageUrl = imageList[_currentIndex].value;

          // 网络图片就保存都指定位置
          await saveImageToLocal(
            currentImageUrl,
            imageName:
                "${widget.title ?? '新闻图片'}_${fileTs(DateTime.now())}.jpg",
            dlDir: await getDioDownloadDir(),
          );

          ToastUtils.showToast("图片已保存");
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
