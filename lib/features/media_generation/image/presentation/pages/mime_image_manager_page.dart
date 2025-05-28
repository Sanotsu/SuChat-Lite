import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../common/pages/mime_media_manager_base.dart';
import 'mime_image_preview_page.dart';

class MimeImageManagerPage extends MimeMediaManagerBase {
  const MimeImageManagerPage({super.key});

  @override
  State<MimeImageManagerPage> createState() => _MimeImageManagerState();
}

class _MimeImageManagerState
    extends MimeMediaManagerBaseState<MimeImageManagerPage> {
  @override
  String get title => '图片管理';

  @override
  CusMimeCls get mediaType => CusMimeCls.IMAGE;

  @override
  Widget buildPreviewPage(File file) {
    return MimeImagePreviewPage(
      file: file,
      onDelete: () {
        setState(() {
          mediaList.remove(file);
        });
      },
    );
  }
}
