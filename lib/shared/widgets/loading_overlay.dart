import 'dart:async';
import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static DateTime? _startTime;
  static Duration _elapsedTime = Duration.zero;

  static void show(
    BuildContext context, {
    VoidCallback? onCancel,
    String title = "处理中",
    List<String> messages = const ["请耐心等待一会儿", "请勿退出当前页面"],
    Color backgroundColor = Colors.black54,
    Color textColor = Colors.white,
    bool showCancelButton = true,
    bool showTimer = false,
  }) {
    if (_overlayEntry != null) return;

    // 初始化计时器
    _startTime = DateTime.now();
    _elapsedTime = Duration.zero;

    if (showTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_startTime != null) {
          _elapsedTime = DateTime.now().difference(_startTime!);
          // 强制刷新overlay
          _overlayEntry?.markNeedsBuild();
        }
      });
    }

    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: backgroundColor,
          child: Center(
            child: Card(
              elevation: 8,
              color: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...messages.map(
                      (message) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          message,
                          style: TextStyle(fontSize: 14, color: textColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (showTimer) ...[
                      const SizedBox(height: 12),
                      Text(
                        '用时: ${_formatDuration(_elapsedTime)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (showCancelButton) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          hide();
                          onCancel?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("取消"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _elapsedTime = Duration.zero;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 格式化时间显示
  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 预设的媒体生成遮罩
  static void showMediaGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
    String mediaType = "媒体",
    bool showTimer = true,
  }) {
    final String title = "$mediaType生成中";
    final List<String> messages = [
      "正在生成$mediaType，请耐心等待",
      "生成过程中请勿退出当前页面",
      "取消操作可能导致生成失败",
    ];

    show(
      context,
      onCancel: onCancel,
      title: title,
      messages: messages,
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      textColor: Colors.white,
      showCancelButton: true,
      showTimer: showTimer,
    );
  }

  // 图片生成遮罩
  static void showImageGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
    bool showTimer = true,
  }) {
    showMediaGeneration(
      context,
      onCancel: onCancel,
      mediaType: "图片",
      showTimer: showTimer,
    );
  }

  // 视频生成遮罩
  static void showVideoGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
    bool showTimer = true,
  }) {
    showMediaGeneration(
      context,
      onCancel: onCancel,
      mediaType: "视频",
      showTimer: showTimer,
    );
  }

  // 音频生成遮罩
  static void showVoiceGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
    bool showTimer = true,
  }) {
    showMediaGeneration(
      context,
      onCancel: onCancel,
      mediaType: "音频",
      showTimer: showTimer,
    );
  }

  // 训练计划生成遮罩
  static void showTrainingPlanGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
    bool showTimer = true,
  }) {
    show(
      context,
      onCancel: onCancel,
      title: "训练计划生成中",
      messages: ["正在为您量身定制训练计划，请耐心等待", "生成过程中请勿退出当前页面", "大约需要2分钟，使用推理模型耗时会更久"],
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      textColor: Colors.white,
      showCancelButton: true,
      showTimer: showTimer,
    );
  }
}
