import 'package:flutter/material.dart';

import '../../../common/pages/mime_media_preview_base.dart';

class MimeImagePreviewPage extends MimeMediaPreviewBase {
  const MimeImagePreviewPage({super.key, required super.file, super.onDelete});

  @override
  String get title => '图片预览';

  @override
  Widget buildPreviewContent() {
    return InteractiveViewer(
      child: Center(child: Image.file(file, fit: BoxFit.contain)),
    );
  }
}
