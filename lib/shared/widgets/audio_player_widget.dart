import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/screen_helper.dart';

/// 通用音频播放器组件
/// 基于VideoPlayer构建，可以在移动端和桌面端使用
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? sourceType; // 'file', 'network', 'asset'
  final Color primaryColor;
  final Color secondaryColor;
  final Color? backgroundColor; // 背景色(对话页面可设置透明)
  final bool autoPlay;
  final bool showWaveform; // 是否显示波形图，目前还未实现，预留
  final bool dense; // 是否紧凑型(对话主页面就可以只显示一行一个按钮)
  final bool onlyIcon; // 如果只显示图标，则返回一个按钮(没有进度条、没有前进后退等额外控制按钮)
  final double? witdh;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.sourceType = 'file',
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.lightBlue,
    this.backgroundColor,
    this.autoPlay = false,
    this.showWaveform = false,
    this.dense = false,
    this.onlyIcon = false,
    this.witdh,
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
    _cleanupTempAsset();
    super.dispose();
  }

  // 清理临时asset文件
  Future<void> _cleanupTempAsset() async {
    if (_tempAssetPath != null) {
      try {
        final file = File(_tempAssetPath!);
        if (await file.exists()) await file.delete();
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
    try {
      _controller = switch (widget.sourceType) {
        "network" => VideoPlayerController.networkUrl(
          Uri.parse(widget.audioUrl),
        ),
        // 将资源文件复制到临时目录后再构建控制器
        "asset" => VideoPlayerController.file(
          File(await _loadAssetToTemp(widget.audioUrl)),
        ),
        _ => VideoPlayerController.file(File(widget.audioUrl)),
      };

      await _controller.initialize();

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _duration = _controller.value.duration;
      });

      // 监听音频位置变化
      _controller.addListener(_audioListener);

      // 是否自动播放
      if (widget.autoPlay) {
        await _controller.play();
        if (!mounted) return;
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('初始化音频控制器失败: $e');
      if (!mounted) return;
      setState(() => _isInitialized = false);
    }
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

  // 统一构建按钮
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double sizeFactor = 1.0,
    Color? color,
    String? tooltip,
  }) {
    // 基础尺寸定义
    final iconSize = widget.dense ? 12.0 : 16.0;
    final minSize = widget.dense ? 16.0 : 24.0;

    return IconButton(
      constraints: BoxConstraints(
        // 减少最小宽度和高度，使点击区域更紧凑
        minWidth: ScreenHelper.adaptWidth(minSize * sizeFactor),
        minHeight: ScreenHelper.adaptHeight(minSize * sizeFactor * 0.6),
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        icon,
        size: ScreenHelper.adaptWidth(iconSize * sizeFactor),
        color: color ?? widget.primaryColor,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      if (widget.onlyIcon || widget.dense) {
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.primaryColor),
            const SizedBox(height: 16),
            Text(
              '加载音频中...',
              style: TextStyle(fontSize: ScreenHelper.getFontSize(14)),
            ),
          ],
        ),
      );
    }

    // 如果只显示图标，则返回一个按钮(没有进度条、没有前进后退等额外控制按钮)
    if (widget.onlyIcon) {
      return _buildIconButton(
        icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        onPressed: _togglePlayPause,
        color: widget.secondaryColor,
        sizeFactor: ScreenHelper.isDesktop() ? 1.5 : 2.4,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: ScreenHelper.adaptPadding(EdgeInsets.all(widget.dense ? 4 : 8)),
      width: widget.witdh ?? (widget.dense ? 300 : null),
      height: widget.dense ? (ScreenHelper.isDesktop() ? 40 : 60) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 波形图（预留，暂未实现）
          if (widget.showWaveform)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text('音频波形图（开发中）', style: TextStyle(color: Colors.grey)),
              ),
            ),
          // 进度条和时间显示
          _buildSliderRow(),
          // 如果是密集型，则不显示单独行控制按钮
          if (!widget.dense) _buildControlRow(),
        ],
      ),
    );
  }

  Widget _buildSliderRow() {
    final textStyle = TextStyle(
      fontSize: ScreenHelper.getFontSize(11),
      color: widget.secondaryColor,
    );

    return Row(
      children: [
        // 当前时间
        Text(_formatDuration(_position), style: textStyle),
        // 进度条
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: ScreenHelper.adaptWidth(
                  widget.dense ? 3 : 5,
                ),
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: ScreenHelper.adaptWidth(widget.dense ? 6 : 12),
              ),
              trackHeight: ScreenHelper.adaptHeight(widget.dense ? 2 : 4),
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
        Text(_formatDuration(_duration), style: textStyle),
        // 如果是密集型，则只显示播放/暂停按钮，不显示单独按钮行
        if (widget.dense)
          _buildIconButton(
            icon:
                _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
            onPressed: _togglePlayPause,
            sizeFactor: ScreenHelper.isDesktop() ? 1.5 : 2.4,
          ),
      ],
    );
  }

  Widget _buildControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 静音控制(后续可以修改滚动条控制音频)
        _buildIconButton(
          icon:
              _controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
          onPressed: () {
            _controller.setVolume(_controller.value.volume > 0 ? 0 : 1.0);
            setState(() {});
          },
          color: widget.secondaryColor,
          tooltip: _controller.value.volume > 0 ? '静音' : '取消静音',
        ),
        SizedBox(width: ScreenHelper.adaptWidth(16)),
        // 向后5秒
        _buildIconButton(
          icon: Icons.replay_5,
          onPressed: () => _seekRelative(const Duration(seconds: -5)),
          sizeFactor: widget.dense ? 1.0 : 1.5,
        ),
        // 播放/暂停
        _buildIconButton(
          icon:
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          onPressed: _togglePlayPause,
          sizeFactor: widget.dense ? 1.5 : 2.0,
        ),
        // 向前5秒
        _buildIconButton(
          icon: Icons.forward_5,
          onPressed: () => _seekRelative(const Duration(seconds: 5)),
          sizeFactor: widget.dense ? 1.0 : 1.5,
        ),
        SizedBox(width: ScreenHelper.adaptWidth(16)),
        // 重新播放
        _buildIconButton(
          icon: Icons.replay,
          onPressed: _replay,
          color: widget.secondaryColor,
          tooltip: '重新播放',
        ),
      ],
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _controller.play() : _controller.pause();
    });
  }

  void _seekRelative(Duration duration) {
    final newPosition = _position + duration;
    _controller.seekTo(newPosition > _duration ? _duration : newPosition);
  }

  void _replay() {
    _controller.seekTo(Duration.zero);
    _controller.play();
    setState(() => _isPlaying = true);
  }
}
