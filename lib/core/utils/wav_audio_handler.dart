import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'datetime_formatter.dart';
import 'get_dir.dart';

class WavAudioHandler {
  static const int sampleRate = 24000; // 24kHz
  static const int channels = 1; // 单声道
  static const int bitDepth = 16; // 16位深度

  static Uint8List createWavFile(Uint8List pcmData) {
    final byteData = ByteData(44); // WAV头固定44字节

    // RIFF块
    byteData.setUint32(0, 0x46464952, Endian.little); // "RIFF" (注意字节序)
    byteData.setUint32(4, pcmData.length + 36, Endian.little); // 文件总大小-8

    // WAVE格式
    byteData.setUint32(8, 0x45564157, Endian.little); // "WAVE"
    byteData.setUint32(12, 0x20746d66, Endian.little); // "fmt "

    // fmt子块
    byteData.setUint32(16, 16, Endian.little); // fmt块大小(16字节)
    byteData.setUint16(20, 1, Endian.little); // PCM格式=1
    byteData.setUint16(22, channels, Endian.little); // 声道数
    byteData.setUint32(24, sampleRate, Endian.little); // 采样率
    byteData.setUint32(
      28,
      sampleRate * channels * bitDepth ~/ 8,
      Endian.little,
    ); // 字节率
    byteData.setUint16(32, channels * bitDepth ~/ 8, Endian.little); // 块对齐
    byteData.setUint16(34, bitDepth, Endian.little); // 位深度

    // data子块
    byteData.setUint32(36, 0x61746164, Endian.little); // "data"
    byteData.setUint32(40, pcmData.length, Endian.little); // 数据大小

    // 合并头和PCM数据
    final wavFile =
        Uint8List(44 + pcmData.length)
          ..setRange(0, 44, byteData.buffer.asUint8List())
          ..setRange(44, 44 + pcmData.length, pcmData);

    return wavFile;
  }

  static Future<void> saveWavFile(Uint8List wavData, String filePath) async {
    await File(filePath).writeAsBytes(wavData);
  }

  /// 保存到文件
  static Future<String> saveBase64Wav(
    String base64Audio, {
    String? model,
  }) async {
    // 1. 解码Base64
    Uint8List pcmData = base64.decode(base64Audio);

    // 2. 创建WAV文件
    Uint8List wavData = createWavFile(pcmData);

    // 3. 保存文件
    final directory = await getOmniChatVoiceGenDir();
    final filePath =
        '${directory.path}/${model ?? 'omni_audio'}_${fileTs(DateTime.now())}.wav';

    await saveWavFile(wavData, filePath);

    return filePath;
  }
}
