import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../models/brief_ai_tools/branch_chat/branch_chat_export_data.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_store.dart';
import '../../../common/components/toast_utils.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/file_picker_helper.dart';
import '../../../common/utils/screen_helper.dart';

class ChatExportImportPage extends StatefulWidget {
  const ChatExportImportPage({super.key});

  @override
  State<ChatExportImportPage> createState() => _ChatExportImportPageState();
}

class _ChatExportImportPageState extends State<ChatExportImportPage> {
  bool isExporting = false;
  bool isImporting = false;

  @override
  Widget build(BuildContext context) {
    // 判断平台类型
    final isDesktop = ScreenHelper.isDesktop();

    // 获取屏幕尺寸
    final size = MediaQuery.of(context).size;

    // 计算内容的最大宽度
    final maxWidth = isDesktop ? size.width * 0.6 : size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('对话记录导入导出'),
        centerTitle: true,
        elevation: isDesktop ? 1.0 : null,
      ),
      // 使用SingleChildScrollView防止内容溢出
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 添加简短说明
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        '在这里，您可以导出对话记录以备份，或者导入之前备份的对话记录。',
                        style: TextStyle(fontSize: 16.0, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  _buildExportSection(size),
                  SizedBox(height: 48.0),
                  _buildImportSection(size),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection(Size size) {
    // 计算按钮宽度，窄屏时自适应，宽屏时固定
    final useFixedButtonWidth = size.width > 400;
    final buttonWidth = useFixedButtonWidth ? 140.0 : null;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 适应窄屏的标题和按钮布局
            if (size.width < 360)
              _buildNarrowExportHeader(buttonWidth)
            else
              _buildWideExportHeader(buttonWidth),

            SizedBox(height: 8.0),
            Text(
              '将所有对话记录导出为JSON文件，可用于备份或迁移到其他设备。',
              style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // 窄屏时的导出标题和按钮（垂直排列）
  Widget _buildNarrowExportHeader(double? buttonWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Icon(Icons.download_rounded, color: Colors.blue),
              SizedBox(width: 8.0),
              Text(
                '导出对话',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildExportButton(buttonWidth),
        ),
      ],
    );
  }

  // 宽屏时的导出标题和按钮（水平排列）
  Widget _buildWideExportHeader(double? buttonWidth) {
    return Row(
      children: [
        Icon(Icons.download_rounded, color: Colors.blue),
        SizedBox(width: 8.0),
        Text(
          '导出对话',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        _buildExportButton(buttonWidth),
      ],
    );
  }

  // 导出按钮
  Widget _buildExportButton(double? buttonWidth) {
    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton.icon(
        onPressed: isExporting ? null : _handleBranchChatExport,
        icon:
            isExporting
                ? SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.file_download, size: 18.0),
        label: Text(isExporting ? '导出中...' : '导出对话'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        ),
      ),
    );
  }

  Widget _buildImportSection(Size size) {
    // 计算按钮宽度，窄屏时自适应，宽屏时固定
    final useFixedButtonWidth = size.width > 400;
    final buttonWidth = useFixedButtonWidth ? 140.0 : null;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 适应窄屏的标题和按钮布局
            if (size.width < 360)
              _buildNarrowImportHeader(buttonWidth)
            else
              _buildWideImportHeader(buttonWidth),

            SizedBox(height: 8.0),
            Text(
              '从JSON文件导入对话记录，并合并到现有对话中。重复的会话将被跳过。',
              style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // 窄屏时的导入标题和按钮（垂直排列）
  Widget _buildNarrowImportHeader(double? buttonWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Icon(Icons.upload_rounded, color: Colors.green),
              SizedBox(width: 8.0),
              Text(
                '导入对话',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildImportButton(buttonWidth),
        ),
      ],
    );
  }

  // 宽屏时的导入标题和按钮（水平排列）
  Widget _buildWideImportHeader(double? buttonWidth) {
    return Row(
      children: [
        Icon(Icons.upload_rounded, color: Colors.green),
        SizedBox(width: 8.0),
        Text(
          '导入对话',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        _buildImportButton(buttonWidth),
      ],
    );
  }

  // 导入按钮
  Widget _buildImportButton(double? buttonWidth) {
    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton.icon(
        onPressed: isImporting ? null : _handleBranchChatImport,
        icon:
            isImporting
                ? SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.file_upload, size: 18.0),
        label: Text(isImporting ? '导入中...' : '导入对话'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        ),
      ),
    );
  }

  Future<void> _handleBranchChatExport() async {
    setState(() => isExporting = true);

    try {
      // 1. 获取所有会话数据
      final store = await BranchStore.create();
      final sessions = store.sessionBox.getAll();

      // 2. 转换为导出格式
      final exportData = BranchChatExportData(
        sessions:
            sessions
                .map((session) => BranchChatSessionExport.fromSession(session))
                .toList(),
      );

      // 3. 获取下载目录并创建文件
      final fileName =
          'SuChat对话记录_${DateTime.now().millisecondsSinceEpoch}.json';

      try {
        // 先尝试使用 FilePicker 选择保存位置
        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择保存位置',
        );

        if (result != null) {
          final file = File('$result${Platform.pathSeparator}$fileName');
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(exportData.toJson()),
          );

          ToastUtils.showSuccess(
            '导出成功：${file.path}',
            duration: Duration(seconds: 5),
          );
        }
      } catch (e) {
        if (!mounted) return;
        commonExceptionDialog(context, '选择目录失败', '选择目录失败: $e');

        // 如果选择目录失败，则使用默认下载目录
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Downloads');
          if (!downloadsDir.existsSync()) {
            downloadsDir.createSync(recursive: true);
          }

          final file = File(
            '${downloadsDir.path}${Platform.pathSeparator}$fileName',
          );
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(exportData.toJson()),
          );

          if (!mounted) return;
          commonHintDialog(context, '导出成功', '导出成功：${file.path}');
        } else {
          throw Exception('无法获取存储目录');
        }
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导出失败', '导出失败: $e');
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  Future<void> _handleBranchChatImport() async {
    setState(() => isImporting = true);

    try {
      // 1. 选择文件
      File? result = await FilePickerHelper.pickAndSaveFile(
        fileType: CusFileType.custom,
        allowedExtensions: ['json'],
        overwrite: true,
      );

      if (result != null) {
        // 2. 读取文件内容
        final file = File(result.path);
        final store = await BranchStore.create();
        final importResult = await store.importSessionHistory(file);

        final importedCount = importResult.importedCount;
        final skippedCount = importResult.skippedCount;

        if (!mounted) return;

        // 根据导入结果显示不同的提示
        if (importedCount > 0) {
          String message = '成功导入 $importedCount 个会话';
          if (skippedCount > 0) {
            message += '，跳过 $skippedCount 个重复会话';
          }
          ToastUtils.showInfo(message, duration: Duration(seconds: 5));
        } else if (skippedCount > 0) {
          ToastUtils.showInfo(
            '所有会话($skippedCount 个)均已存在，未导入任何内容',
            duration: Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '导入失败', e.toString());
    } finally {
      if (mounted) {
        setState(() => isImporting = false);
      }
    }
  }
}
