import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    VoidCallback? onCancel,
    String title = "处理中",
    List<String> messages = const ["请耐心等待一会儿", "请勿退出当前页面"],
    Color backgroundColor = Colors.black54,
    Color textColor = Colors.white,
    bool showCancelButton = true,
  }) {
    if (_overlayEntry != null) return;

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
                    SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
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
                    if (showCancelButton) ...[
                      SizedBox(height: 20),
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
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 预设的媒体生成遮罩
  static void showMediaGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
    String mediaType = "媒体",
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
    );
  }

  // 图片生成遮罩
  static void showImageGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
  }) {
    showMediaGeneration(context, onCancel: onCancel, mediaType: "图片");
  }

  // 视频生成遮罩
  static void showVideoGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
  }) {
    showMediaGeneration(context, onCancel: onCancel, mediaType: "视频");
  }

  // 音频生成遮罩
  static void showVoiceGeneration(
    BuildContext context, {
    VoidCallback? onCancel,
  }) {
    showMediaGeneration(context, onCancel: onCancel, mediaType: "音频");
  }
}
