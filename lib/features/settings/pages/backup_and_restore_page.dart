// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'dart:typed_data';

import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/datetime_formatter.dart';
import '../../../shared/widgets/toast_utils.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../../core/utils/file_picker_utils.dart';
import '../../../core/utils/screen_helper.dart';
import '../services/backup_utils.dart';
import 'restore_wizard_page.dart';

class BackupAndRestorePage extends StatefulWidget {
  // 主页面有获取，直接传入，不要再次获取
  final String packageVersion;

  const BackupAndRestorePage({super.key, required this.packageVersion});

  @override
  State<BackupAndRestorePage> createState() => _BackupAndRestorePageState();
}

class _BackupAndRestorePageState extends State<BackupAndRestorePage> {
  bool isLoading = false;

  String note =
      """**全量备份** 是把应用本地数据库中的所有数据导出保存在本地，包括智能助手的对话历史(新旧聊天模块)、搭档角色、账单列表、菜品列表等，消息中引用的图片/语音等小媒体也会一并打包。
\n\n**合并恢复** 是把 '全量备份' 导出的压缩包，重新导入到应用中。导入时不会删除应用中的现有的数据：备份中已有的数据会覆盖同编号的现有数据，恢复前新增的其他数据全部保留。
\n\n视频等大文件不在全量备份内，可通过"媒体文件包"单独导出。""";

  @override
  void initState() {
    super.initState();
  }

  ///
  /// 全量备份(0.1.5 改版)：
  /// 1. 系统保存器选位置(免存储权限，iOS也可用)
  /// 2. 流式构建zip(内存占用恒定)：
  ///    数据json + 外观设置 + 清单 + 小媒体(单文件≤10MB，总配额500MB)
  /// 3. 视频等大文件经"媒体文件包"单独导出
  ///
  Future<void> exportAllData({bool includeMedia = true}) async {
    if (!mounted) return;

    final zipName = '$ZIP_FILE_PREFIX${fileTs(DateTime.now())}.zip';

    // 系统保存器选择保存位置(file_picker 12 要求 bytes 必填：传空占位，
    // 仅借系统保存器拿到目标路径，zip 随后流式写入覆盖)
    final Uri? saveUri = await FilePicker.saveFile(
      fileName: zipName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List(0),
    );
    if (saveUri == null) return; // 用户取消
    final String savePath = saveUri.toFilePath();
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 阶段提示：每阶段关旧开新(BotToast 不支持更新文字)，结束后必关
      CancelFunc? closeLoading;
      await BackupUtils.buildDataPack(
        zipPath: savePath,
        includeMedia: includeMedia,
        onStage: (stage) {
          if (mounted) {
            closeLoading?.call();
            closeLoading = ToastUtils.showLoading('正在备份... $stage');
          }
        },
      );
      closeLoading?.call();

      setState(() {
        isLoading = false;
      });

      ToastUtils.showSuccess(
        '备份已保存到: $savePath',
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('保存操作出现错误: $e');
      ToastUtils.showError('备份失败: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 导出大媒体文件包(视频等未纳入全量备份的大文件)
  Future<void> exportMediaPack() async {
    if (!mounted || isLoading) return;

    final zipName = '$MEDIA_PACK_PREFIX${fileTs(DateTime.now())}.zip';
    final Uri? saveUri = await FilePicker.saveFile(
      fileName: zipName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List(0),
    );
    if (saveUri == null) return;
    final String savePath = saveUri.toFilePath();

    setState(() {
      isLoading = true;
    });

    try {
      // 之前未持有 CancelFunc，loading 遮罩永不关闭锁死界面
      final closeLoading = ToastUtils.showLoading('正在扫描大媒体文件...');
      try {
        final result = await BackupUtils.buildMediaPack(zipPath: savePath);
        closeLoading();

        setState(() {
          isLoading = false;
        });

        if (result.includedCount == 0) {
          ToastUtils.showInfo('没有需要单独打包的大媒体文件');
          File(savePath).deleteSync();
        } else {
          ToastUtils.showSuccess(
            '媒体包已保存到: $savePath\n(共${result.includedCount}个文件)',
            duration: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        closeLoading();
        rethrow;
      }
    } catch (e) {
      ToastUtils.showError('导出媒体包失败: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  ///
  /// 2023-12-11 恢复的话，简单需要导出时同名的zip压缩包
  /// 2026-08-31 由"覆写恢复"改为"合并恢复"：
  ///   不再删除现有数据库，备份中的数据直接合并进现有数据库——
  ///   已存在同主键的数据用备份覆盖，库中已有的其他数据全部保留。
  ///   这样用户使用一段时间后再恢复旧备份，也不会丢失恢复前新增的数据。
  ///
  /// 1. 获取用户选择的压缩文件
  /// 2. 判断选中的文件是否符合导出的文件格式(匹配前缀和后缀，不符合不做任何操作)
  /// 3. 处理导入过程
  ///   3.1 先解压压缩包，读取json文件
  ///   3.2 先将数据库中的数据备份到临时文件夹中(万一恢复出问题还有补救)
  ///   3.3 将json文件依次合并导入数据库(同主键覆盖，不同主键保留)
  ///   3.4 json文件导入成功，则删除临时备份文件
  ///
  ///
  /// 2026-09-01 恢复入口改为三步向导(解析预览 -> 模块/会话勾选 -> 进度执行)：
  /// 解决旧流程"无进度、不能部分恢复"两个问题
  ///
  Future<void> restoreDataFromBackup() async {
    File? file = await FilePickerUtils.pickAndSaveFile(
      fileType: CusFileType.custom,
      // 导出时指定为zip，所以这里也限制为zip
      allowedExtensions: ['zip'],
    );

    if (file == null) return; // 用户取消选择
    if (isLoading) return;

    debugPrint("获取的上传zip文件路径：${p.basename(file.path)}");

    // 这个判断虽然不准确，但先这样
    if (p.basename(file.path).startsWith(ZIP_FILE_PREFIX) &&
        p.basename(file.path).toLowerCase().endsWith('.zip')) {
      if (!mounted) return;
      // 进入恢复向导：解析预览 -> 勾选模块/会话 -> 进度执行
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestoreWizardPage(zipFile: file),
        ),
      );
    } else {
      ToastUtils.showError("用于恢复的备份文件格式不对，恢复已取消。");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("备份恢复"),
        actions: [
          IconButton(
            onPressed: () {
              commonMarkdwonHintDialog(
                context,
                "备份恢复说明",
                note,
                msgFontSize: 15,
              );
            },
            icon: const Icon(Icons.info_outline),
            tooltip: '帮助',
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 40),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildBackupCard(),
                            SizedBox(width: 20),
                            _buildRestoreCard(),
                            SizedBox(width: 20),
                            _buildMediaPackCard(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildInfoSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Icon(
          Icons.import_export,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          "数据备份与恢复",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "保护您的数据安全，随时备份和恢复",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackupCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showBackupConfirmationDialog();
        },
        child: Padding(
          padding: EdgeInsets.all(ScreenHelper.isDesktop() ? 32 : 16.0),
          child: Column(
            children: [
              Icon(Icons.backup, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                "全量备份",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (ScreenHelper.isDesktop())
                Text(
                  "导出所有数据到备份文件",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text(
                  "立即备份",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () {
                  _showBackupConfirmationDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: restoreDataFromBackup,
        child: Padding(
          padding: EdgeInsets.all(ScreenHelper.isDesktop() ? 32 : 16.0),
          child: Column(
            children: [
              Icon(Icons.restore, size: 40, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                "合并恢复",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (ScreenHelper.isDesktop())
                Text(
                  "从备份文件合并恢复数据(不删除现有数据)",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  "选择文件",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: restoreDataFromBackup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPackCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: exportMediaPack,
        child: Padding(
          padding: EdgeInsets.all(ScreenHelper.isDesktop() ? 32 : 16.0),
          child: Column(
            children: [
              const Icon(
                Icons.video_collection,
                size: 40,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              const Text(
                "媒体文件包",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (ScreenHelper.isDesktop())
                const Text(
                  "单独导出视频等大媒体文件",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.movie, color: Colors.white),
                label: const Text(
                  "导出媒体包",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: exportMediaPack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        const Text(
          "温馨提示",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "1. 定期备份可防止数据丢失\n"
          "2. 恢复为合并模式：现有数据不会被删除\n"
          "3. 聊天模块的API密钥不在备份包内，恢复后需重新配置\n"
          "4. 旧版聊天数据恢复时会自动转换导入新版聊天模块",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showBackupConfirmationDialog() {
    bool includeMedia = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("全量备份"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("确认导出所有数据到备份文件？"),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: includeMedia,
                  onChanged: (v) =>
                      setDialogState(() => includeMedia = v ?? true),
                  title: const Text("包含消息中的媒体文件"),
                  subtitle: const Text(
                    "图片/语音等小媒体(单文件≤10MB，总量≤500MB)随包保存；\n"
                    "视频等大文件请使用\"媒体文件包\"单独导出",
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, false);
                },
                child: const Text("取消"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text("确认备份"),
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value != null && value) exportAllData(includeMedia: includeMedia);
    });
  }
}
