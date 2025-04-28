import 'package:flutter/material.dart';
import '../common/mime_media_preview_base.dart';
import 'audio_player_widget.dart';

class MimeVoicePreview extends MimeMediaPreviewBase {
  const MimeVoicePreview({super.key, required super.file, super.onDelete});

  @override
  String get title => '语音预览';

  @override
  Widget buildPreviewContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),

          // 音频播放器
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AudioPlayerWidget(audioUrl: file.path, sourceType: 'file'),
          ),

          SizedBox(height: 40),

          // 文件信息
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.insert_drive_file_outlined,
                    '文件名称',
                    file.path.split('/').last,
                  ),
                  Divider(),
                  _buildInfoRow(Icons.folder_outlined, '文件位置', file.path),
                  Divider(),
                  _buildInfoRow(
                    Icons.sd_storage_outlined,
                    '文件大小',
                    _formatFileSize(file.lengthSync()),
                  ),
                  Divider(),
                  _buildInfoRow(
                    Icons.access_time_outlined,
                    '创建时间',
                    _formatDateTime(file.lastModifiedSync()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法：格式化文件大小
  String _formatFileSize(int size) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double s = size.toDouble();
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(2)} ${suffixes[i]}';
  }

  // 辅助方法：格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
  }

  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  // 辅助方法：构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
