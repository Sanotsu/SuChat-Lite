import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../services/backup_utils.dart';
import '../services/restore_executor.dart';

/// 恢复向导预览条目
class RestorePreviewItem {
  final String fileName; // 小写json文件名
  final String module; // 模块显示名
  final int itemCount;
  bool selected;

  // 新版聊天-对话的会话级预览
  final List<RestorePreviewConversation>? conversations;

  RestorePreviewItem({
    required this.fileName,
    required this.module,
    required this.itemCount,
    this.selected = true,
    this.conversations,
  });
}

class RestorePreviewConversation {
  final String id;
  final String title;
  final int messageCount;
  final DateTime updatedAt;
  bool selected;
  RestorePreviewConversation({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.updatedAt,
    this.selected = true,
  });
}

/// 备份包恢复向导(2026-09-01)
/// 三步：解析预览 -> 勾选 -> 进度执行 -> 结果报告
/// 解决旧流程"无进度、不能部分恢复"两个问题
class RestoreWizardPage extends StatefulWidget {
  final File zipFile;

  const RestoreWizardPage({super.key, required this.zipFile});

  @override
  State<RestoreWizardPage> createState() => _RestoreWizardPageState();
}

class _RestoreWizardPageState extends State<RestoreWizardPage> {
  // 步骤：0解析中 1预览勾选 2执行中 3结果报告
  int _step = 0;
  String? _parseError;

  List<RestorePreviewItem> _items = [];
  String _unzipPath = '';
  List<File> _jsonFiles = const [];

  // 执行状态
  double _progress = 0;
  String _currentModule = '';
  List<RestoreModuleReport> _reports = [];
  bool _execError = false;

  // 0.1.5 媒体恢复统计
  int _mediaRestored = 0;
  int _mediaExcluded = 0;

  @override
  void initState() {
    super.initState();
    _parseBackup();
  }

  Future<void> _parseBackup() async {
    setState(() {
      _step = 0;
      _parseError = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      _unzipPath = p.join(tempDir.path, ZIP_TEMP_DIR_AT_UNZIP);

      // 解压+列出json文件(isolate中执行，避免大zip卡UI)
      final files = await compute(_unzipAndScanSync, {
        'zipPath': widget.zipFile.path,
        'unzipPath': _unzipPath,
      });

      _jsonFiles = files.map((e) => File(e)).toList();
      final items = <RestorePreviewItem>[];

      for (final file in _jsonFiles) {
        final filename = p.basename(file.path).toLowerCase();
        final module = RestoreExecutor.moduleNameOf(filename);

        // 新版聊天-对话：解析会话清单供勾选
        if (filename == 'suchat_unified_conversation.json') {
          final convs = await compute(_scanConversations, file.path);
          items.add(
            RestorePreviewItem(
              fileName: filename,
              module: module,
              itemCount: convs.length,
              conversations: convs,
            ),
          );
          continue;
        }

        // 旧版聊天历史：解析会话数
        if (filename == BRANCH_CHAT_HISTORY_FILE_NAME) {
          final count = await compute(_scanBranchSessionCount, file.path);
          items.add(
            RestorePreviewItem(
              fileName: filename,
              module: module,
              itemCount: count,
            ),
          );
          continue;
        }

        // 其余：数条目
        final count = await compute(_countListJson, file.path);
        items.add(
          RestorePreviewItem(
            fileName: filename,
            module: module,
            itemCount: count,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parseError = '备份包解析失败: $e';
        _step = 1;
        _items = [];
      });
    }
  }

  Future<void> _startRestore() async {
    final selectedFiles = _items
        .where((i) => i.selected)
        .map((i) => i.fileName)
        .toSet();

    if (selectedFiles.isEmpty) {
      ToastUtils.showInfo('请至少勾选一个要恢复的模块');
      return;
    }

    // 新版聊天会话级选择：勾了对话/消息表时收集勾选会话
    Set<String>? convIds;
    final convItem = _items.where(
      (i) => i.fileName == 'suchat_unified_conversation.json' && i.selected,
    );
    final msgSelected = selectedFiles.contains(
      'suchat_unified_chat_message.json',
    );
    if (convItem.isNotEmpty && msgSelected) {
      final convs = convItem.first.conversations;
      if (convs != null) {
        final ids = convs.where((c) => c.selected).map((c) => c.id).toSet();
        // 全选时传null走全量(更快)
        convIds = ids.length == convs.length ? null : ids;
        if (convIds != null && convIds.isEmpty) {
          ToastUtils.showInfo('请至少勾选一个要恢复的对话');
          return;
        }
      }
    }

    setState(() {
      _step = 2;
      _progress = 0;
      _currentModule = '准备恢复...';
      _reports = [];
      _execError = false;
    });

    try {
      // 恢复前安全网：先把当前数据备份到临时zip(成功后删除)
      final tempDir = await getTemporaryDirectory();
      final tempZipDir = await Directory(
        p.join(tempDir.path, ZIP_TEMP_DIR_AT_RESTORE),
      ).create();
      final zipName =
          "$ZIP_FILE_PREFIX${DateTime.now().millisecondsSinceEpoch}.zip";
      await BackupUtils.buildDataPack(
        zipPath: p.join(tempZipDir.path, zipName),
        includeMedia: false,
      );

      final result = await RestoreExecutor().execute(
        jsonFiles: _jsonFiles,
        selection: RestoreSelection(
          selectedFiles: selectedFiles,
          unifiedConvIds: convIds,
        ),
        unzipDir: Directory(_unzipPath),
        onProgress: (module, done, total) {
          if (!mounted) return;
          setState(() {
            _progress = total == 0 ? 1 : done / total;
            _currentModule = '$module ($done/$total)';
          });
        },
      );

      // 成功恢复后删除临时安全网备份
      final safetyZip = File(p.join(tempZipDir.path, zipName));
      if (safetyZip.existsSync()) safetyZip.deleteSync();

      if (!mounted) return;
      setState(() {
        _reports = result.modules;
        _mediaRestored = result.mediaRestored;
        _mediaExcluded = result.mediaExcluded;
        _step = 3;
        _progress = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _execError = true;
        _parseError = e.toString();
        _step = 3;
      });
    } finally {
      // 清理解压临时文件
      try {
        await BackupUtils.deleteFilesInDirectory(_unzipPath);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('恢复备份')),
      body: switch (_step) {
        0 => _buildParsingView(),
        2 => _buildProgressView(),
        3 => _buildResultView(),
        _ => _buildPreviewView(),
      },
    );
  }

  Widget _buildParsingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在解析备份包...\n${p.basename(widget.zipFile.path)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============ 预览勾选 ============

  Widget _buildPreviewView() {
    if (_parseError != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(_parseError!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '备份文件: ${p.basename(widget.zipFile.path)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '选择要恢复的模块(合并模式：不删除现有数据，同编号数据会被备份内容覆盖)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              ..._items.map(_buildModuleTile),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildModuleTile(RestorePreviewItem item) {
    final isConv = item.conversations != null;
    return Theme(
      // 去掉CheckboxListTile自带内边距干扰
      data: Theme.of(context),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(
          children: [
            Checkbox(
              value: item.selected,
              onChanged: (v) => _toggleModule(item, v == true),
            ),
            Expanded(child: Text(item.module)),
            Text(
              '${item.itemCount} 条',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: isConv
            ? (item.conversations!)
                  .map(
                    (c) => CheckboxListTile(
                      dense: true,
                      value: c.selected,
                      title: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${c.messageCount} 条消息',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onChanged: (v) => setState(() => c.selected = v == true),
                    ),
                  )
                  .toList()
            : [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '该模块不支持展开选择，恢复时整体导入',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
      ),
    );
  }

  void _toggleModule(RestorePreviewItem item, bool selected) {
    setState(() {
      item.selected = selected;
      // 新版聊天-对话：模块切换时同步全选/全清会话
      if (item.conversations != null) {
        for (final c in item.conversations!) {
          c.selected = selected;
        }
      }
    });
  }

  Widget _buildBottomBar() {
    final selectedCount = _items.where((i) => i.selected).length;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '已选 $selectedCount/${_items.length} 个模块',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          ElevatedButton(onPressed: _startRestore, child: const Text('开始恢复')),
        ],
      ),
    );
  }

  // ============ 执行进度 ============

  Widget _buildProgressView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('正在合并恢复...', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const LinearProgressIndicator(minHeight: 8),
            const SizedBox(height: 12),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _currentModule,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '恢复前已自动创建临时安全备份，请勿退出应用',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  // ============ 结果报告 ============

  Widget _buildResultView() {
    final failed = _reports.where((r) => r.error != null).toList();
    final imported = _reports.where((r) => r.imported > 0).toList();
    final skippedUser = _reports.where((r) => r.skipped == -1).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _execError || failed.isNotEmpty
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              size: 64,
              color: _execError || failed.isNotEmpty
                  ? Colors.orange
                  : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _execError ? '恢复出错' : '恢复完成',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '成功模块: ${imported.length}\n未勾选跳过: $skippedUser\n失败模块: ${failed.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (_mediaRestored > 0 || _mediaExcluded > 0) ...[
              const SizedBox(height: 8),
              Text(
                _mediaExcluded > 0
                    ? '媒体文件已恢复 $_mediaRestored 个；'
                          '另有 $_mediaExcluded 个大媒体(视频等)未包含在本备份中'
                    : '媒体文件已恢复 $_mediaRestored 个',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              '合并恢复不会删除现有数据；\n聊天模块的API密钥不在备份包内，需重新配置。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (failed.isNotEmpty || _execError) ...[
              Container(
                margin: const EdgeInsets.only(top: 12),
                constraints: const BoxConstraints(maxHeight: 140),
                child: SingleChildScrollView(
                  child: Text(
                    [
                      if (_execError) _parseError ?? '',
                      ...failed.map((r) => '${r.module}: ${r.error}'),
                    ].where((s) => s.isNotEmpty).join('\n'),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ isolate 顶层函数(预览解析，避免卡UI) ============

/// isolate中解压备份并列出json文件路径(同步执行)
List<String> _unzipAndScanSync(Map<String, String> args) {
  final unzipPath = args['unzipPath']!;
  final dir = Directory(unzipPath);
  if (dir.existsSync()) {
    for (final e in dir.listSync()) {
      if (e is File) e.deleteSync();
    }
  } else {
    dir.createSync(recursive: true);
  }
  extractFileToDisk(args['zipPath']!, unzipPath);
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .map((f) => f.path)
      .toList();
}

/// 数json列表条目(isolate)
int _countListJson(String path) {
  try {
    final list = jsonDecode(File(path).readAsStringSync()) as List;
    return list.length;
  } catch (_) {
    return 0;
  }
}

/// 数旧版聊天会话数(isolate)
int _scanBranchSessionCount(String path) {
  try {
    final data =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final sessions = (data['sessions'] as List?) ?? [];
    return sessions.length;
  } catch (_) {
    return 0;
  }
}

/// 解析新版会话清单(isolate)
List<RestorePreviewConversation> _scanConversations(String path) {
  try {
    final list = jsonDecode(File(path).readAsStringSync()) as List;
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return RestorePreviewConversation(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '(无标题)',
        messageCount: (m['message_count'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (m['updated_at'] as num?)?.toInt() ?? 0,
        ),
      );
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  } catch (_) {
    return [];
  }
}
