import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../core/utils/get_dir.dart';
import '../../../../../core/utils/simple_tools.dart';

class Daily60SPage extends StatefulWidget {
  final String? title;
  final String? imageUrl;

  const Daily60SPage({super.key, this.imageUrl, this.title});

  @override
  State<Daily60SPage> createState() => _Daily60SPageState();
}

class _Daily60SPageState extends State<Daily60SPage> {
  // 直接获取图片、可直接显示的地址（不稳定）
  String imageUrl() =>
      "https://api.03c3.cn/api/zb?random=${DateTime.now().millisecondsSinceEpoch}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? '每天60秒读懂世界')),
      body: InteractiveViewer(
        panEnabled: true, // 是否允许平移
        boundaryMargin: EdgeInsets.all(8),
        minScale: 0.1, // 最小缩放比例
        maxScale: 4.0, // 最大缩放比例
        child: SingleChildScrollView(
          child: GestureDetector(
            // 长按保存到相册
            onLongPress: () async {
              // 网络图片就保存都指定位置
              await saveImageToLocal(
                imageUrl(),
                imageName: "每天60秒_${fileTs(DateTime.now())}.jpg",
                dlDir: await getDioDownloadDir(),
              );
            },
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl ?? imageUrl(),
              // width: MediaQuery.of(context).size.width,
              width: 1.sw,
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) =>
                  const Center(child: Text("图片暂时无法显示，请稍候重试。")),
            ),
          ),
        ),
      ),
    );
  }
}
