import 'dart:io';

import 'package:flutter/material.dart';

import '../../../common/constants/constants.dart';
import '../../../common/utils/screen_helper.dart';
import '../common/mime_media_manager_base.dart';
import 'mime_voice_preview.dart';

class MimeVoiceManager extends MimeMediaManagerBase {
  const MimeVoiceManager({super.key});

  @override
  State<MimeVoiceManager> createState() => _MimeVoiceManagerState();
}

class _MimeVoiceManagerState
    extends MimeMediaManagerBaseState<MimeVoiceManager> {
  @override
  String get title => '语音管理';

  @override
  CusMimeCls get mediaType => CusMimeCls.AUDIO;

  @override
  Widget buildPreviewScreen(File file) {
    return MimeVoicePreview(
      file: file,
      onDelete: () {
        setState(() {
          mediaList.remove(file);
        });
      },
    );
  }

  @override
  Widget buildMediaGridItem(File file, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isMultiSelectMode) {
          setState(() {
            if (isSelected) {
              selectedMedia.remove(file);
              if (selectedMedia.isEmpty) {
                isMultiSelectMode = false;
              }
            } else {
              selectedMedia.add(file);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => buildPreviewScreen(file)),
          );
        }
      },
      onLongPress: () {
        if (!isMultiSelectMode) {
          setState(() {
            isMultiSelectMode = true;
            selectedMedia.add(file);
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: ScreenHelper.isDesktop() ? 32 : 24,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 8),
                  Text(
                    file.path.split('/').last,
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Container(
              color: Colors.blue.withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: Icon(Icons.check_circle, color: Colors.white, size: 30),
            ),
        ],
      ),
    );
  }
}
