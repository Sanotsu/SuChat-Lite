import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/get_dir.dart';
import '../../../../shared/widgets/toast_utils.dart';

class NoteAudioRecorder extends StatefulWidget {
  final Function(File audioFile) onAudioRecorded;
  final Directory? audioDir;

  const NoteAudioRecorder({
    super.key,
    required this.onAudioRecorded,
    this.audioDir,
  });

  @override
  State<NoteAudioRecorder> createState() => _NoteAudioRecorderState();
}

class _NoteAudioRecorderState extends State<NoteAudioRecorder> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // 创建临时录音文件
        final appDir = widget.audioDir ?? await getVoiceRecordingDir();
        final audioPath = path.join(
          appDir.path,
          '笔记录音_${fileTs(DateTime.now())}.m4a',
        );

        // 配置录音参数
        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: audioPath);

        setState(() {
          _isRecording = true;
        });
      } else {
        ToastUtils.showError('没有录音权限');
      }
    } catch (e) {
      ToastUtils.showError('开始录音失败: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        widget.onAudioRecorded(File(path));
      }
    } catch (e) {
      ToastUtils.showError('停止录音失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 暂时只显示一个录音按钮
    return IconButton(
      icon: Icon(
        _isRecording ? Icons.stop : Icons.mic,
        color: _isRecording ? Colors.red : null,
      ),
      onPressed: _isRecording ? _stopRecording : _startRecording,
    );
  }
}
