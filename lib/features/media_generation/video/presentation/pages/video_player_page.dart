import 'package:flutter/material.dart';

import '../../../../../shared/widgets/video_player_widget.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? sourceType;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    this.sourceType = 'file',
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
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
