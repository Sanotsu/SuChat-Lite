import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/screen_helper.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? sourceType;
  // 是否紧凑型(true,只显示进度条和播放/暂停按钮；false，显示进度条、播放/暂停按钮、音量控制、快进快退等按钮)
  final bool dense;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.sourceType = 'file',
    this.dense = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // 桌面平台使用 video_player_media_kit
    if (ScreenHelper.isDesktop()) {
      // MediaKit初始化已由插件内部处理，不需要额外初始化代码
    }

    if (widget.sourceType == "network") {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    }

    _controller.initialize().then((_) {
      // 监听视频位置变化
      _controller.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
        //// 自动播放
        // _controller.play();
        // _isPlaying = true;
        _controller.pause();
        _isPlaying = false;
      }
    });
  }

  void _videoListener() {
    if (mounted && _controller.value.isInitialized) {
      setState(() {
        _position = _controller.value.position;
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '加载视频中...',
              style: TextStyle(fontSize: ScreenHelper.getFontSize(14)),
            ),
          ],
        ),
      );
    }

    // 使用SingleChildScrollView确保在桌面端窗口变小时可以滚动
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算视频尺寸，确保不超出屏幕宽度
        final maxWidth = constraints.maxWidth;
        // 移动端可以正常获取到比例，实测Ubuntu下没获取到所有返回size为0,比例是1.0
        // final aspectRatio = _controller.value.aspectRatio;

        // 测试
        final aspectRatio = ScreenHelper.isDesktop()
            ? 3 / 2
            : _controller.value.aspectRatio;

        final videoHeight = maxWidth / aspectRatio;

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 视频播放器
              SizedBox(
                width: maxWidth,
                height: videoHeight,
                child: VideoPlayer(_controller),
              ),

              // 紧贴视频的控制器区域
              Container(
                // color: Colors.black12,
                padding: ScreenHelper.adaptPadding(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 进度条和时间显示
                    buildSliderRow(),

                    /// 如果是密集型，则不显示单独行控制按钮
                    if (!widget.dense) buildControlRow(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Row buildSliderRow() {
    return Row(
      children: [
        // 当前时间
        Text(
          _formatDuration(_position),
          style: TextStyle(
            fontSize: ScreenHelper.getFontSize(11),
            color: Colors.grey[700],
          ),
        ),

        // 进度条
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: ScreenHelper.adaptWidth(5),
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: ScreenHelper.adaptWidth(12),
              ),
              trackHeight: ScreenHelper.adaptHeight(2),
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              min: 0.0,
              max: _duration.inMilliseconds.toDouble(),
              activeColor: Colors.blue,
              inactiveColor: Colors.grey[300],
              onChanged: (value) {
                _controller.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),

        // 总时长
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            fontSize: ScreenHelper.getFontSize(11),
            color: Colors.grey[700],
          ),
        ),

        // 如果是密集型，则只显示播放/暂停按钮，不显示单独按钮行
        if (widget.dense)
        // 播放/暂停
        ...[
          SizedBox(width: ScreenHelper.adaptWidth(16)),
          IconButton(
            constraints: BoxConstraints(
              minWidth: ScreenHelper.adaptWidth(32),
              minHeight: ScreenHelper.adaptHeight(32),
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: ScreenHelper.adaptWidth(28),
              color: Colors.blue,
            ),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _isPlaying ? _controller.play() : _controller.pause();
              });
            },
          ),
        ],
      ],
    );
  }

  Row buildControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 音量控制
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(32),
            minHeight: ScreenHelper.adaptHeight(32),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            _controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
            size: ScreenHelper.adaptWidth(20),
            color: Colors.grey[700],
          ),
          onPressed: () {
            _controller.setVolume(_controller.value.volume > 0 ? 0 : 1.0);
            setState(() {});
          },
          tooltip: _controller.value.volume > 0 ? '静音' : '取消静音',
        ),

        // 分隔
        SizedBox(width: ScreenHelper.adaptWidth(16)),

        // 向后10秒
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(36),
            minHeight: ScreenHelper.adaptHeight(36),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.replay_10,
            size: ScreenHelper.adaptWidth(24),
            color: Colors.blue,
          ),
          onPressed: () {
            final newPosition = _position - const Duration(seconds: 10);
            _controller.seekTo(
              newPosition < Duration.zero ? Duration.zero : newPosition,
            );
          },
        ),

        // 播放/暂停
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(48),
            minHeight: ScreenHelper.adaptHeight(48),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: ScreenHelper.adaptWidth(40),
            color: Colors.blue,
          ),
          onPressed: () {
            setState(() {
              _isPlaying = !_isPlaying;
              _isPlaying ? _controller.play() : _controller.pause();
            });
          },
        ),

        // 向前10秒
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(36),
            minHeight: ScreenHelper.adaptHeight(36),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.forward_10,
            size: ScreenHelper.adaptWidth(24),
            color: Colors.blue,
          ),
          onPressed: () {
            final newPosition = _position + const Duration(seconds: 10);
            _controller.seekTo(
              newPosition > _duration ? _duration : newPosition,
            );
          },
        ),

        // 分隔
        SizedBox(width: ScreenHelper.adaptWidth(16)),

        // 重新播放
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(32),
            minHeight: ScreenHelper.adaptHeight(32),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.replay,
            size: ScreenHelper.adaptWidth(20),
            color: Colors.grey[700],
          ),
          onPressed: () {
            _controller.seekTo(Duration.zero);
            _controller.play();
            setState(() {
              _isPlaying = true;
            });
          },
          tooltip: '重新播放',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }
}
