import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/skill_models.dart';
import '../../data/services/skills/skill_github_service.dart';
import '../../data/services/skills/skill_parser.dart';
import '../../data/services/skills/skill_storage_service.dart';

/// Agent Skills 技能管理页（P1-4/P1-5）
/// 列表/启用开关/删除/预览全文 + 手动导入（zip：全平台；目录：桌面端）。
/// 对齐 MCP 设置页形态。
class SkillsSettingsPage extends StatefulWidget {
  const SkillsSettingsPage({super.key});

  @override
  State<SkillsSettingsPage> createState() => _SkillsSettingsPageState();
}

class _SkillsSettingsPageState extends State<SkillsSettingsPage> {
  final SkillStorageService _storage = SkillStorageService();
  final SkillGitHubService _github = SkillGitHubService();

  List<SkillMeta>? _skills;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final skills = await _storage.getAllSkills();
    if (!mounted) return;
    setState(() => _skills = skills);
  }

  /// 2026-09-16 P3-2 批量从源更新：GitHub来源技能按repo分组(同repo一次
  /// fetchCandidates覆盖多个技能)，逐组重拉覆盖安装；SKILL.md文本比对
  /// 区分"有更新/无变化"，失败按组计数并汇总展示。复用_importing覆盖态
  Future<void> _updateAllFromSource() async {
    final githubSkills = (_skills ?? const <SkillMeta>[])
        .where((s) => s.source.startsWith('github:'))
        .toList();
    if (githubSkills.isEmpty) {
      ToastUtils.showInfo('没有 GitHub 来源的技能可更新');
      return;
    }

    setState(() => _importing = true);
    var updated = 0;
    var unchanged = 0;
    var failed = 0;
    final errors = <String>[];
    try {
      // 按repo分组(source格式为 github:owner/repo)
      final byRepo = <String, List<SkillMeta>>{};
      for (final s in githubSkills) {
        byRepo
            .putIfAbsent(s.source.substring('github:'.length), () => [])
            .add(s);
      }

      for (final entry in byRepo.entries) {
        final parsed = SkillGitHubService.parseRepoInput(entry.key);
        if (parsed == null) {
          failed += entry.value.length;
          errors.add('${entry.key}: 来源标记无法解析');
          continue;
        }
        try {
          final candidates = await _github.fetchCandidates(
            parsed.owner,
            parsed.repo,
          );
          for (final skill in entry.value) {
            final matched = candidates
                .where((c) => c.parseResult.name == skill.name)
                .toList();
            if (matched.isEmpty) {
              failed++;
              errors.add('${skill.name}: 源仓库中已不存在');
              continue;
            }
            final before = await _storage.readSkillMarkdown(skill.name);
            await _github.installCandidate(
              matched.first,
              parsed.owner,
              parsed.repo,
            );
            final after = await _storage.readSkillMarkdown(skill.name);
            if (before.trim() != after.trim()) {
              updated++;
            } else {
              unchanged++;
            }
          }
        } on SkillGitHubException catch (e) {
          failed += entry.value.length;
          errors.add('${entry.key}: ${e.message}');
        } finally {
          await _github.cleanup();
        }
      }
    } finally {
      if (mounted) setState(() => _importing = false);
      await _reload();
    }

    final summary = StringBuffer('更新完成: $updated 个有更新，$unchanged 个无变化');
    if (failed > 0) summary.write('，$failed 个失败');
    if (mounted) ToastUtils.showInfo(summary.toString());
    if (errors.isNotEmpty && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('更新失败详情'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final e in errors.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(e, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _importZip() async {
    // file_picker 12 静态API：pickFile 返回单个 PlatformFile?
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = picked?.path;
    if (path == null) return;
    await _doImport(() => _storage.importFromZip(File(path)));
  }

  Future<void> _importDirectory() async {
    final dirPath = await FilePicker.getDirectoryPath();
    if (dirPath == null) return;
    await _doImport(() => _storage.importFromDirectory(Directory(dirPath)));
  }

  Future<void> _doImport(Future<SkillMeta> Function() action) async {
    setState(() => _importing = true);
    try {
      final meta = await action();
      if (!mounted) return;
      ToastUtils.showSuccess('技能 "${meta.name}" 导入成功');
      await _reload();
    } on SkillParseException catch (e) {
      if (mounted) ToastUtils.showError(e.message);
    } on SkillImportException catch (e) {
      if (mounted) ToastUtils.showError(e.message);
    } catch (e) {
      if (mounted) ToastUtils.showError('导入失败: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _toggle(SkillMeta skill, bool value) async {
    await _storage.setEnabled(skill.name, value);
    await _reload();
  }

  Future<void> _delete(SkillMeta skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除技能'),
        content: Text('确定删除技能 "${skill.name}"？其文件将一并移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.deleteSkill(skill.name);
    if (!mounted) return;
    ToastUtils.showInfo('已删除');
    await _reload();
  }

  Future<void> _openPreview(SkillMeta skill) async {
    String content;
    try {
      content = await _storage.readSkillMarkdown(skill.name);
    } catch (e) {
      if (mounted) ToastUtils.showError('读取失败: $e');
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillPreviewPage(skill: skill, content: content),
      ),
    );
  }

  String _sourceLabel(SkillMeta skill) {
    if (skill.source.startsWith('github:')) {
      return skill.source.substring('github:'.length);
    }
    if (skill.source == 'import') return '本地导入';
    return skill.source;
  }

  String _sizeLabel(SkillMeta skill) {
    if (skill.fileSize < 1024) return '${skill.fileSize}B';
    if (skill.fileSize < 1024 * 1024) {
      return '${(skill.fileSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(skill.fileSize / 1024 / 1024).toStringAsFixed(1)}MB';
  }

  // =========================================================================
  // P2-1 GitHub 安装
  // =========================================================================

  Future<void> _showGitHubInstallDialog({String? initialInput}) async {
    final inputController = TextEditingController(text: initialInput);
    final selected = <String>{};
    List<GitHubSkillCandidate>? candidates;
    String? owner;
    String? repo;
    var fetching = false;
    var installing = false;
    String? installProgress;
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        // 2026-09-16 UI统一：弹窗宽度走 dialogWidth 640 档
        // (Align先转loose再限宽，tight下ConstrainedBox失效——项目标准模式)
        builder: (context, setDialogState) => Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CusContentWidth.dialogWidth,
            ),
            child: AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('从 GitHub 安装技能'),
              content: SizedBox(
                width: double.maxFinite,
                child: candidates == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: inputController,
                            enabled: !fetching,
                            decoration: const InputDecoration(
                              labelText: '仓库 (owner/repo)',
                              hintText:
                                  '如 anthropics/skills 或粘贴 GitHub/skills.sh 链接',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '将拉取仓库全量压缩包并扫描其中的 SKILL.md 技能；'
                              '未配置token时每小时约60次',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          if (fetching)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('正在拉取仓库压缩包…'),
                                ],
                              ),
                            ),
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$owner/$repo 扫描到 ${candidates!.length} 个技能，勾选安装：',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          // 2026-09-16 扫描诊断(跳过N个/截断提示)
                          if (_github.lastScanNote != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _github.lastScanNote!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (final c in candidates!)
                                    CheckboxListTile(
                                      dense: true,
                                      value: selected.contains(c.name),
                                      onChanged: installing
                                          ? null
                                          : (v) => setDialogState(() {
                                              v == true
                                                  ? selected.add(c.name)
                                                  : selected.remove(c.name);
                                            }),
                                      title: Text(
                                        c.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        '${c.description ?? '(无描述)'}\n'
                                        '附属 ${c.auxCount} 个 · '
                                        '${(c.totalSize / 1024).toStringAsFixed(1)}KB',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (installProgress != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(installProgress!),
                            ),
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: installing
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                if (candidates == null)
                  TextButton(
                    onPressed: fetching
                        ? null
                        : () async {
                            final parsed = SkillGitHubService.parseRepoInput(
                              inputController.text,
                            );
                            if (parsed == null) {
                              setDialogState(
                                () => error = '请输入 owner/repo 或仓库链接',
                              );
                              return;
                            }
                            setDialogState(() {
                              fetching = true;
                              error = null;
                            });
                            try {
                              final list = await _github.fetchCandidates(
                                parsed.owner,
                                parsed.repo,
                              );
                              setDialogState(() {
                                candidates = list;
                                owner = parsed.owner;
                                repo = parsed.repo;
                                fetching = false;
                              });
                            } on SkillGitHubException catch (e) {
                              setDialogState(() {
                                fetching = false;
                                error = e.message;
                              });
                            } catch (e) {
                              setDialogState(() {
                                fetching = false;
                                error = '拉取失败: $e';
                              });
                            }
                          },
                    child: const Text('获取技能'),
                  )
                else
                  TextButton(
                    onPressed: installing || selected.isEmpty
                        ? null
                        : () async {
                            setDialogState(() => installing = true);
                            var okCount = 0;
                            final failed = <String>[];
                            final chosen = candidates!
                                .where((c) => selected.contains(c.name))
                                .toList();
                            for (var i = 0; i < chosen.length; i++) {
                              final c = chosen[i];
                              setDialogState(
                                () => installProgress =
                                    '正在安装 ${c.name}(${i + 1}/${chosen.length})…',
                              );
                              try {
                                await _github.installCandidate(
                                  c,
                                  owner!,
                                  repo!,
                                );
                                okCount++;
                              } catch (e) {
                                failed.add('${c.name}: $e');
                              }
                            }
                            await _github.cleanup();
                            setDialogState(() {
                              installing = false;
                              installProgress = null;
                              error = failed.isEmpty
                                  ? null
                                  : '部分失败:\n${failed.join('\n')}';
                            });
                            await _reload();
                            if (!mounted) return;
                            if (failed.isEmpty) {
                              ToastUtils.showSuccess('已安装 $okCount 个技能');
                              if (context.mounted) Navigator.pop(context, true);
                            }
                          },
                    child: const Text('安装所选'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await _github.cleanup();
    if (confirmed == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final skills = _skills;

    // 2026-09-16 UI统一：设置类页面对齐 CusContentWidth.form(720)档
    return CusContentWidth.form(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Skills 技能'),
          actions: [
            // 2026-09-16 P3-2 批量从源更新(GitHub来源技能，按repo分组去重拉取)
            IconButton(
              tooltip: '更新全部 GitHub 技能',
              onPressed: _importing ? null : _updateAllFromSource,
              icon: const Icon(Icons.sync),
            ),
            // 2026-09-16 SKILLS P2-1 从 GitHub 仓库安装
            IconButton(
              tooltip: '从 GitHub 安装',
              onPressed: _importing ? null : _showGitHubInstallDialog,
              icon: const Icon(Icons.cloud_download_outlined),
            ),
            IconButton(
              tooltip: '导入 zip 技能包',
              onPressed: _importing ? null : _importZip,
              icon: const Icon(Icons.upload_file),
            ),
            // 目录导入仅桌面端（移动端无系统目录浏览器，PLAN 4.4）
            if (!Platform.isAndroid && !Platform.isIOS)
              IconButton(
                tooltip: '导入技能目录',
                onPressed: _importing ? null : _importDirectory,
                icon: const Icon(Icons.folder_open),
              ),
          ],
        ),
        body: _importing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('正在导入与解析技能…'),
                  ],
                ),
              )
            : skills == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildRecommendationStrip(),
                  Expanded(child: _buildSkillList(skills)),
                ],
              ),
      ),
    );
  }

  /// 2026-09-18 清单预算设置卡已下架：语义翻转后清单只来自搭档显式
  /// 挂载，预算退化为skill_manager内部防呆常量(见catalogBudget注释)

  /// 2026-09-16 P3 精选推荐源：内置repo坐标清单(内容从源头拉取最新版，
  /// 无版权风险)，点击预填安装对话框
  Widget _buildRecommendationStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, size: 14, color: Colors.amber[700]),
              const SizedBox(width: 4),
              const Text(
                '精选技能源(点击一键安装)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final rec in SkillRecommendations.items)
                  _buildRecommendationCard(rec),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(SkillRecommendation rec) {
    final installed = _skills?.any(
      (s) =>
          s.source == 'github:${rec.repo}' ||
          s.sourceUrl?.endsWith(rec.repo) == true,
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _importing
            ? null
            : () => _showGitHubInstallDialog(initialInput: rec.repo),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rec.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (installed == true)
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  rec.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              Text(
                '${rec.repo}${installed == true ? ' · 已安装' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillList(List<SkillMeta> skills) {
    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '暂无技能\n点击上方精选源一键安装\n或右上角导入 zip / 从 GitHub 安装',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, i) {
        final skill = skills[i];
        return ListTile(
          dense: true,
          title: Text(skill.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${skill.description ?? '(无描述)'}\n'
            '来源: ${_sourceLabel(skill)} · 附属 ${skill.auxCount} 个 · '
            '${_sizeLabel(skill)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: skill.enabled, onChanged: (v) => _toggle(skill, v)),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(skill),
              ),
            ],
          ),
          onTap: () => _openPreview(skill),
        );
      },
    );
  }
}

/// 技能全文预览页（monospace 可选中复制——H3 安装知情要求）。
/// P2-2：附来源仓库跳转与附属文件列表
class SkillPreviewPage extends StatefulWidget {
  const SkillPreviewPage({
    super.key,
    required this.skill,
    required this.content,
  });

  final SkillMeta skill;
  final String content;

  @override
  State<SkillPreviewPage> createState() => _SkillPreviewPageState();
}

class _SkillPreviewPageState extends State<SkillPreviewPage> {
  final SkillStorageService _storage = SkillStorageService();
  final SkillGitHubService _github = SkillGitHubService();

  /// 正文可变副本(P3-2 从源更新覆盖安装后刷新显示)
  late String _content = widget.content;

  List<String>? _auxFiles;

  /// 是否正在从源更新(AppBar按钮loading)
  bool _updating = false;

  /// 2026-09-16 P3-5 运行要求标注：预览时实时重解析frontmatter提取
  /// allowed-tools/compatibility(作者写给用户的运行时提示)——不落DB
  /// (渐进披露：浏览时才解析)，解析失败静默忽略
  String? _compatibility;
  List<String>? _allowedTools;

  @override
  void initState() {
    super.initState();
    _extractRuntimeRequirements(_content);
    _loadAuxFiles();
  }

  void _extractRuntimeRequirements(String raw) {
    try {
      final parsed = SkillParser.parse(raw);
      final compat = parsed.scalarFields['compatibility'];
      final tools = parsed.scalarFields['allowed-tools'];
      _compatibility = (compat == null || compat.isEmpty) ? null : compat;
      _allowedTools = (tools == null || tools.isEmpty)
          ? null
          : tools
                .split(RegExp(r'[,，]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
    } on SkillParseException {
      // 用户手改导致解析失败：标注缺失不影响正文浏览
      _compatibility = null;
      _allowedTools = null;
    }
  }

  /// 2026-09-16 P3-2 从源更新：重拉仓库覆盖安装(保留启用态)，完成后
  /// 重新加载本页内容；"无变化"也如实反馈
  Future<void> _updateFromSource() async {
    if (_updating) return;
    setState(() => _updating = true);
    String message;
    try {
      final result = await _github.updateSkillFromSource(widget.skill);
      message = result.changed
          ? '技能 "${widget.skill.name}" 已更新到最新版'
          : '技能 "${widget.skill.name}" 已是最新版';
      // 重新加载内容/运行要求/附属列表(覆盖安装后文件可能已变)
      final fresh = await _storage.readSkillMarkdown(widget.skill.name);
      if (!mounted) return;
      setState(() {
        _content = fresh;
        _extractRuntimeRequirements(fresh);
        _auxFiles = null;
      });
      await _loadAuxFiles();
    } on SkillGitHubException catch (e) {
      message = e.message;
    } catch (e) {
      message = '更新失败: $e';
    } finally {
      if (mounted) setState(() => _updating = false);
    }
    if (!mounted) return;
    ToastUtils.showInfo(message);
  }

  Future<void> _loadAuxFiles() async {
    final files = await _storage.listAuxFiles(widget.skill.name);
    if (!mounted) return;
    setState(() => _auxFiles = files);
  }

  @override
  Widget build(BuildContext context) {
    final repoUrl = widget.skill.sourceUrl;
    final canUpdate = widget.skill.source.startsWith('github:');

    // 2026-09-16 UI统一：详情/正文页对齐内容档(1000)；正文走项目
    // markdown渲染器(monospace纯文本可读性差且无标题/列表结构)
    return CusContentWidth(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.skill.name, style: const TextStyle(fontSize: 16)),
          actions: [
            // 2026-09-16 P3-2 从源更新(仅GitHub来源技能显示)
            if (canUpdate)
              IconButton(
                tooltip: '从源更新',
                onPressed: _updating ? null : _updateFromSource,
                icon: _updating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '来源: ${widget.skill.source}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (repoUrl != null && repoUrl.isNotEmpty)
                    InkWell(
                      onTap: () => launchStringUrl(repoUrl),
                      child: Text(
                        repoUrl,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                '附属文件: ${_auxFiles == null
                    ? '扫描中…'
                    : _auxFiles!.isEmpty
                    ? '无'
                    : _auxFiles!.join('、')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            // 2026-09-16 P3-5 运行要求标注(frontmatter的compatibility/
            // allowed-tools，作者声明的运行时依赖；两者都缺省不显示)
            if (_compatibility != null || _allowedTools != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  '${_compatibility != null ? '运行要求: $_compatibility\n' : ''}'
                  '${_allowedTools != null ? '依赖工具: ${_allowedTools!.join(', ')}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const Divider(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  child: CusMarkdownRenderer.instance.render(
                    _content,
                    selectable: ScreenHelper.isDesktop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
