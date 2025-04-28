import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../../../common/utils/screen_helper.dart';

/// 通用音频播放器组件
/// 基于VideoPlayer构建，可以在移动端和桌面端使用
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? sourceType; // 'file', 'network', 'asset'
  final Color primaryColor;
  final Color secondaryColor;
  final bool autoPlay;
  final bool showWaveform; // 是否显示波形图，目前还未实现，预留

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.sourceType = 'file',
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.lightBlue,
    this.autoPlay = false,
    this.showWaveform = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _tempAssetPath;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    // 删除临时资源文件
    _cleanupTempAsset();
    super.dispose();
  }

  // 清理临时asset文件
  Future<void> _cleanupTempAsset() async {
    if (_tempAssetPath != null) {
      try {
        final file = File(_tempAssetPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('清理临时文件失败: $e');
      }
    }
  }

  // 将asset音频文件复制到临时目录
  Future<String> _loadAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());
    return tempFile.path;
  }

  void _initializeController() async {
    if (widget.sourceType == "network") {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.audioUrl),
      );
    } else if (widget.sourceType == "asset") {
      // 将资源文件复制到临时目录
      _tempAssetPath = await _loadAssetToTemp(widget.audioUrl);
      _controller = VideoPlayerController.file(File(_tempAssetPath!));
    } else {
      _controller = VideoPlayerController.file(File(widget.audioUrl));
    }

    _controller.initialize().then((_) {
      // 监听音频位置变化
      _controller.addListener(_audioListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });

        // 是否自动播放
        if (widget.autoPlay) {
          _controller.play();
          _isPlaying = true;
        } else {
          _controller.pause();
          _isPlaying = false;
        }
      }
    });
  }

  void _audioListener() {
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
            CircularProgressIndicator(color: widget.primaryColor),
            SizedBox(height: 16),
            Text(
              '加载音频中...',
              style: TextStyle(fontSize: ScreenHelper.getFontSize(14)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: ScreenHelper.adaptPadding(
        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 波形图（预留，暂未实现）
          if (widget.showWaveform)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
              margin: EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text('音频波形图（开发中）', style: TextStyle(color: Colors.grey)),
              ),
            ),

          // 进度条和时间显示
          _buildSliderRow(),

          // 控制按钮行
          _buildControlRow(),
        ],
      ),
    );
  }

  Widget _buildSliderRow() {
    return Row(
      children: [
        // 当前时间
        Text(
          _formatDuration(_position),
          style: TextStyle(
            fontSize: ScreenHelper.getFontSize(11),
            color: widget.secondaryColor,
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
              activeColor: widget.primaryColor,
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
            color: widget.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildControlRow() {
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
            color: widget.secondaryColor,
          ),
          onPressed: () {
            _controller.setVolume(_controller.value.volume > 0 ? 0 : 1.0);
            setState(() {});
          },
          tooltip: _controller.value.volume > 0 ? '静音' : '取消静音',
        ),

        // 分隔
        SizedBox(width: ScreenHelper.adaptWidth(16)),

        // 向后5秒
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(36),
            minHeight: ScreenHelper.adaptHeight(36),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.replay_5,
            size: ScreenHelper.adaptWidth(24),
            color: widget.primaryColor,
          ),
          onPressed: () {
            final newPosition = _position - const Duration(seconds: 5);
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
            color: widget.primaryColor,
          ),
          onPressed: () {
            setState(() {
              _isPlaying = !_isPlaying;
              _isPlaying ? _controller.play() : _controller.pause();
            });
          },
        ),

        // 向前5秒
        IconButton(
          constraints: BoxConstraints(
            minWidth: ScreenHelper.adaptWidth(36),
            minHeight: ScreenHelper.adaptHeight(36),
          ),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.forward_5,
            size: ScreenHelper.adaptWidth(24),
            color: widget.primaryColor,
          ),
          onPressed: () {
            final newPosition = _position + const Duration(seconds: 5);
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
            color: widget.secondaryColor,
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
}
