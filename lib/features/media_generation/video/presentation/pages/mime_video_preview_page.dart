import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../shared/widgets/video_player_widget.dart';
import '../../../common/pages/mime_media_preview_base.dart';

class MimeVideoPreviewPage extends MimeMediaPreviewBase {
  const MimeVideoPreviewPage({super.key, required super.file, super.onDelete});

  @override
  String get title => '视频预览';

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
