import 'dart:io';

import 'package:flutter/material.dart';
import '../common/mime_media_preview_base.dart';
import 'video_preview.dart';

class MimeVideoPreview extends MimeMediaPreviewBase {
  const MimeVideoPreview({super.key, required super.file, super.onDelete});

  @override
  String get title => 'MIME视频预览';

  @override
  Widget buildPreviewContent() {
    return FutureBuilder<File?>(
      future: Future.value(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return VideoPlayerWidget(videoUrl: file.path);
      },
    );
  }
}
