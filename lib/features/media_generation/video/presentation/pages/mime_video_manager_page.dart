import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../common/pages/mime_media_manager_base.dart';
import 'mime_video_preview_page.dart';

class MimeVideoManagerPage extends MimeMediaManagerBase {
  const MimeVideoManagerPage({super.key});

  @override
  State<MimeVideoManagerPage> createState() => _VideoManagerPageState();
}

class _VideoManagerPageState
    extends MimeMediaManagerBaseState<MimeVideoManagerPage> {
  @override
  String get title => '视频管理';

  @override
  CusMimeCls get mediaType => CusMimeCls.VIDEO;

  @override
  Widget buildPreviewPage(File file) {
    return MimeVideoPreviewPage(
      file: file,
      onDelete: () {
        setState(() {
          mediaList.remove(file);
        });
      },
    );
  }
}
