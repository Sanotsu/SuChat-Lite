import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../widgets/news_image_gallery.dart';

/// 有几个API返回的新闻报纸的图片，直接用这个显示
class PaperNewsImagePage extends StatefulWidget {
  final String title;
  final String imageUrl;

  const PaperNewsImagePage({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  State<PaperNewsImagePage> createState() => _PaperNewsImagePageState();
}

class _PaperNewsImagePageState extends State<PaperNewsImagePage> {
  Map<String, String> imageList = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getImages();
  }

  Future<void> getImages() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var respData = await HttpUtils.get(
        path: widget.imageUrl,
        queryParameters: {"type": "json"},
        showLoading: false,
      );

      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      setState(() {
        imageList = (respData as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value.toString()),
        );
      });
    } catch (e) {
      ToastUtils.showError(e.toString());
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: Center(child: CircularProgressIndicator()),
          )
        : NewsImageGallery(imageUrls: imageList, title: widget.title);
  }
}
