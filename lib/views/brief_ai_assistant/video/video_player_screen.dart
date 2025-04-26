import 'package:flutter/material.dart';

import 'video_preview.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? sourceType;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.sourceType = 'file',
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('视频播放示例')),
      body: Padding(
        padding: EdgeInsets.all(5),
        child: VideoPlayerWidget(
          videoUrl: widget.videoUrl,
          sourceType: widget.sourceType,
        ),
      ),
    );
  }
}
