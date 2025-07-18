import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 对话中播放语言消息的气泡样式
/// 来源：https://github.com/SimformSolutionsPvtLtd/audio_waveforms/blob/main/example/lib/chat_bubble.dart
/// 有进行适应性改造
///
class VoiceWaveBubble extends StatefulWidget {
  // 如果是发送者，就靠右边
  final bool isSender;
  // 暂时只支持播放指定路径的语音文件
  final String? path;
  // 声波文件的长度(就是组件的宽度)
  final double? width;

  const VoiceWaveBubble({
    super.key,
    this.isSender = true,
    this.path,
    this.width,
  });

  @override
  State<VoiceWaveBubble> createState() => _VoiceWaveBubbleState();
}

class _VoiceWaveBubbleState extends State<VoiceWaveBubble> {
  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;

  // 语音时长，单位秒，也用于构建组件长度
  int voiceDuration = 0;

  final playerWaveStyle = PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 5,
  );

  @override
  void initState() {
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    if (widget.path == null) {
      return;
    }

    await controller.preparePlayer(
      path: widget.path!,
      shouldExtractWaveform: true,
    );

    if (!mounted) return;
    setState(() {
      // voiceDuration = (controller.maxDuration ~/ 1000);
      // 不丢弃小数，而是向上取整
      voiceDuration = (controller.maxDuration / 1000).ceil();
    });
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 有音频文件才返回，不然就是空
    if (widget.path == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5),
        // height: 36,
        // width: 0.6.sw,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.isSender ? Colors.blue : Colors.lightGreen,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (!widget.isSender && !controller.playerState.isStopped)
              IconButton(
                // 减少最小宽度和高度，使点击区域更紧凑
                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
                onPressed:
                    controller.playerState.isPlaying
                        ? () async {
                          await controller.pausePlayer();
                        }
                        : () async {
                          await controller.startPlayer();
                          controller.setFinishMode(
                            finishMode: FinishMode.pause,
                          );
                        },
                icon: Icon(
                  controller.playerState.isPlaying
                      ? Icons.stop
                      : Icons.play_arrow,
                ),
                color: Colors.white,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            SizedBox(width: 5),
            Text(
              '$voiceDuration"',
              style: const TextStyle(color: Colors.white),
            ),
            SizedBox(width: 5),
            AudioFileWaveforms(
              // 直接使用语音长度来计算(1.sw/60/2*语音时长)，因为最长60s，最长只给一半宽度
              // size: Size(1.sw / 60 / 2 * voiceDuration, 20),
              size: Size(widget.width ?? 1.sw / 2, 32),
              playerController: controller,
              waveformType: WaveformType.long,
              playerWaveStyle: playerWaveStyle,
              padding: EdgeInsets.only(right: 10),
            ),

            // 如果是用户发送，按钮在后面
            if (widget.isSender && !controller.playerState.isStopped)
              IconButton(
                // 减少最小宽度和高度，使点击区域更紧凑
                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
                onPressed:
                    controller.playerState.isPlaying
                        ? () async {
                          await controller.pausePlayer();
                        }
                        : () async {
                          await controller.startPlayer();
                          controller.setFinishMode(
                            finishMode: FinishMode.pause,
                          );
                        },
                icon: Icon(
                  controller.playerState.isPlaying
                      ? Icons.stop
                      : Icons.play_arrow,
                ),
                color: Colors.white,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
