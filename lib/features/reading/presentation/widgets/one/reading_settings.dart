import 'package:flutter/material.dart';

/// ONE阅读设置组件
class OneReadingSettings extends StatefulWidget {
  final bool isDarkMode;
  final double fontSize;
  final bool showReadingProgress;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onShowProgressChanged;

  const OneReadingSettings({
    super.key,
    required this.isDarkMode,
    required this.fontSize,
    required this.showReadingProgress,
    required this.onDarkModeChanged,
    required this.onFontSizeChanged,
    required this.onShowProgressChanged,
  });

  @override
  State<OneReadingSettings> createState() => _OneReadingSettingsState();
}

class _OneReadingSettingsState extends State<OneReadingSettings> {
  late bool _isDarkMode;
  late double _fontSize;
  late bool _showReadingProgress;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fontSize = widget.fontSize;
    _showReadingProgress = widget.showReadingProgress;
  }

  void _updateDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    widget.onDarkModeChanged(value);
  }

  void _updateFontSize(double value) {
    setState(() {
      _fontSize = value;
    });
    widget.onFontSizeChanged(value);
  }

  void _updateShowProgress(bool value) {
    setState(() {
      _showReadingProgress = value;
    });
    widget.onShowProgressChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '阅读设置',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 夜间模式
            _buildSettingItem(
              icon: Icons.dark_mode,
              title: '夜间模式',
              subtitle: '保护眼睛，减少疲劳',
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _updateDarkMode,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),

            const Divider(),

            // 字体大小
            _buildSettingItem(
              icon: Icons.text_fields,
              title: '字体大小',
              subtitle: '调整文字显示大小',
              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _fontSize > 12
                          ? () => _updateFontSize(_fontSize - 2)
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _fontSize < 24
                          ? () => _updateFontSize(_fontSize + 2)
                          : null,
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // 阅读进度
            _buildSettingItem(
              icon: Icons.timeline,
              title: '阅读进度',
              subtitle: '显示阅读进度条',
              trailing: Switch(
                value: _showReadingProgress,
                onChanged: _updateShowProgress,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 20),

            // 字体大小预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预览效果',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这是一段示例文字，用于预览当前的字体大小和主题效果。复杂生活的简单享受，为你提供每日精选的文字、图片和音乐。',
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.6,
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.87)
                          : Colors.black.withValues(alpha: 0.87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
