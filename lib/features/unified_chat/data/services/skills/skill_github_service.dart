import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/utils/simple_tools.dart';
import '../../models/skill_models.dart';
import 'skill_parser.dart';
import 'skill_storage_service.dart';

/// GitHub 仓库中的一个技能候选（扫描结果，未入库）
class GitHubSkillCandidate {
  GitHubSkillCandidate({
    required this.parseResult,
    required this.dir,
    required this.auxCount,
    required this.totalSize,
  });

  final SkillParseResult parseResult;
  final Directory dir;
  final int auxCount;
  final int totalSize;

  String get name => parseResult.name;
  String? get description => parseResult.description;
}

/// 拉取/解析失败（用户可读原因）
class SkillGitHubException implements Exception {
  SkillGitHubException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 2026-09-16 精选推荐源（P3 内置方案）：
/// 官方技能仓库(anthropics/skills、vercel-labs/agent-skills等)license
/// 字段为null——打包其SKILL.md再分发有版权风险，故内置"repo坐标推荐
/// 清单"而非内容本体：内容始终从源头拉取最新版，零版权风险。
/// 选型原则：纯知识型优先；CLI增强型标注需shell(桌面端)；官方提供
/// MCP server的工具建议走MCP通道而非技能形式
class SkillRecommendation {
  const SkillRecommendation({
    required this.repo,
    required this.title,
    required this.description,
    this.tags = const [],
  });

  /// 仓库坐标(owner/repo)
  final String repo;

  /// 展示名
  final String title;

  /// 一句话说明
  final String description;

  /// 标签(如 [纯知识, 前端] / [CLI增强, 桌面端])
  final List<String> tags;
}

class SkillRecommendations {
  SkillRecommendations._();

  static const List<SkillRecommendation> items = [
    SkillRecommendation(
      repo: 'anthropics/skills',
      title: 'Anthropic 官方技能集',
      description: 'frontend-design(前端设计方法论)、skill-creator(技能创作)等纯知识型技能',
      tags: ['纯知识', '官方'],
    ),
    SkillRecommendation(
      repo: 'vercel-labs/agent-skills',
      title: 'Vercel 官方技能集',
      description: 'React 最佳实践、Web 设计指南等前端工程向纯知识技能',
      tags: ['纯知识', '官方'],
    ),
    SkillRecommendation(
      repo: 'laolaoshiren/claude-code-skills-zh',
      title: '中文开发者技能集',
      description:
          '20个中文原生技能：中文代码审查/文档生成/测试生成/API测试/安全审计等，'
          'MIT协议，结构标准可直接安装',
      tags: ['纯知识', '中文', 'MIT'],
    ),
    SkillRecommendation(
      repo: 'microsoft/azure-skills',
      title: 'Microsoft Azure 技能集',
      description: 'Azure 云服务操作/迁移/成本优化等云上工作知识',
      tags: ['纯知识', '云'],
    ),
    SkillRecommendation(
      repo: 'obra/superpowers',
      title: 'Superpowers 技能集',
      description: '头脑风暴、系统化调试、TDD等通用工程方法论文集',
      tags: ['纯知识', '方法论'],
    ),
    SkillRecommendation(
      repo: 'vercel-labs/agent-browser',
      title: 'Agent Browser(浏览器自动化)',
      description:
          'AI优先的浏览器控制CLI；需桌面端npm全局安装并下载Chrome后经shell使用，'
          '亦可以MCP方式接入(command: agent-browser, args: [mcp])',
      tags: ['CLI增强', '桌面端', '建议走MCP'],
    ),
  ];
}

/// Agent Skills GitHub 安装服务（P2-1）
/// 输入 owner/repo → 拉 zipball → 解压临时目录 → 宽松扫描 SKILL.md
/// → 返回候选清单供 UI 勾选 → 逐个安装入库。
class SkillGitHubService {
  // 单例
  static final SkillGitHubService _instance = SkillGitHubService._internal();
  factory SkillGitHubService() => _instance;
  SkillGitHubService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      // zipball 可能较大，放宽接收超时
      receiveTimeout: const Duration(minutes: 3),
      responseType: ResponseType.bytes,
      followRedirects: true,
      maxRedirects: 5,
      headers: {'User-Agent': 'suchat_lite'},
    ),
  );

  final SkillStorageService _storage = SkillStorageService();

  /// 扫描深度上限(SKILL.md 相对解压根的目录段数，PLAN 6.4)
  static const int maxScanDepth = 4;

  /// 单仓库候选数上限
  static const int maxCandidates = 20;

  /// 解析用户输入为 owner/repo。支持三种形态：
  /// `owner/repo`、`https://github.com/owner/repo`、`https://skills.sh/owner/repo`
  /// (可带尾部斜杠/子路径，一律取前两段)。非法输入返回 null。
  static ({String owner, String repo})? parseRepoInput(String input) {
    var t = input.trim();
    if (t.isEmpty) return null;
    // 剥离 scheme 与主机(github.com / skills.sh)
    final m = RegExp(
      r'^(?:https?://)?(?:www\.)?(?:github\.com|skills\.sh)/(.+)$',
      caseSensitive: false,
    ).firstMatch(t);
    t = m?.group(1) ?? t;
    // 去掉 .git 后缀与首尾斜杠后取前两段
    t = t.replaceAll(RegExp(r'\.git$'), '');
    final segments = t.split('/').where((s) => s.trim().isNotEmpty).toList();
    if (segments.length < 2) return null;
    final owner = segments[0];
    final repo = segments[1];
    final segPattern = RegExp(r'^[\w.-]+$');
    if (!segPattern.hasMatch(owner) || !segPattern.hasMatch(repo)) return null;
    return (owner: owner, repo: repo);
  }

  /// 拉取仓库 zipball 并扫描技能候选。
  /// 返回的候选持有临时目录引用——安装完毕后必须调用 [cleanup] 释放。
  List<GitHubSkillCandidate> _candidates = [];
  Directory? _tempDir;

  Future<List<GitHubSkillCandidate>> fetchCandidates(
    String owner,
    String repo,
  ) async {
    await cleanup();

    // 1. 拉 zipball(api.github.com 自动跟随默认分支重定向)
    final url = 'https://api.github.com/repos/$owner/$repo/zipball';
    final List<int> bytes;
    try {
      final resp = await _dio.get<List<int>>(
        url,
        options: Options(
          headers: {'Accept': 'application/vnd.github+json'},
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      bytes = resp.data ?? [];
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) {
        throw SkillGitHubException('仓库 $owner/$repo 不存在或为私有');
      }
      if (code == 403) {
        throw SkillGitHubException(
          'GitHub API 访问受限(限流)，请稍后再试(未配置token时每小时约60次)',
        );
      }
      throw SkillGitHubException('网络请求失败: ${e.message ?? e.type.name}');
    }
    if (bytes.isEmpty) {
      throw SkillGitHubException('仓库内容为空');
    }

    // 2. 解压到临时目录
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw SkillGitHubException('仓库压缩包解压失败: $e');
    }
    _tempDir = await Directory.systemTemp.createTemp('skill_repo_');
    for (final file in archive) {
      if (!file.isFile) continue;
      final entryPath = file.name.replaceAll('\\', '/');
      if (p.isAbsolute(entryPath) || entryPath.split('/').contains('..')) {
        await cleanup();
        throw SkillGitHubException('压缩包内含不安全路径: $entryPath');
      }
      final target = File(p.join(_tempDir!.path, entryPath));
      await target.create(recursive: true);
      await target.writeAsBytes(file.content as List<int>);
    }

    // 3. 宽松扫描 SKILL.md(深度≤4；zipball顶层壳目录自然被深度规则容纳)
    final skillFiles = <File>[];
    await for (final entity in _tempDir!.list(recursive: true)) {
      if (entity is! File) continue;
      if (p.basename(entity.path) != 'SKILL.md') continue;
      final rel = p.relative(entity.path, from: _tempDir!.path);
      final depth = p.split(rel).length - 1; // SKILL.md所在目录的深度
      if (depth <= maxScanDepth) skillFiles.add(entity);
    }
    if (skillFiles.isEmpty) {
      // 2026-09-16 诊断增强：区分"完全没有"与"深度超限被排除"
      var deepCount = 0;
      await for (final entity in _tempDir!.list(recursive: true)) {
        if (entity is! File) continue;
        if (p.basename(entity.path) != 'SKILL.md') continue;
        final rel = p.relative(entity.path, from: _tempDir!.path);
        if (p.split(rel).length - 1 > maxScanDepth) deepCount++;
      }
      await cleanup();
      throw SkillGitHubException(
        deepCount > 0
            ? '仓库中找到 $deepCount 个 SKILL.md 但目录深度超过$maxScanDepth层，暂不支持'
            : '仓库中未找到任何 SKILL.md(不是技能仓库？)',
      );
    }

    // 4. 解析为候选(按路径排序；同名去重保留首个；超上限截断)
    skillFiles.sort((a, b) => a.path.compareTo(b.path));
    final seen = <String>{};
    var truncated = false;
    final parseFailures = <String>[];
    for (final f in skillFiles) {
      if (_candidates.length >= maxCandidates) {
        truncated = true;
        break;
      }
      final SkillParseResult parsed;
      try {
        parsed = SkillParser.parse(f.readAsStringSync());
      } on SkillParseException catch (e) {
        final relDir = p.relative(f.parent.path, from: _tempDir!.path);
        parseFailures.add('$relDir: $e');
        pl.w('跳过无法解析的技能($relDir): $e');
        continue;
      }
      if (seen.contains(parsed.name)) continue;
      seen.add(parsed.name);

      final dir = f.parent;
      var auxCount = 0;
      var totalSize = f.lengthSync();
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && p.basename(entity.path) != 'SKILL.md') {
          auxCount++;
          totalSize += entity.lengthSync();
        }
      }
      _candidates.add(
        GitHubSkillCandidate(
          parseResult: parsed,
          dir: dir,
          auxCount: auxCount,
          totalSize: totalSize,
        ),
      );
    }

    if (_candidates.isEmpty) {
      final reason = parseFailures.isEmpty
          ? ''
          : '解析失败原因(前3条): ${parseFailures.take(3).join('；')}';
      await cleanup();
      throw SkillGitHubException(
        '仓库中找到 ${skillFiles.length} 个 SKILL.md 但均无法安装。$reason',
      );
    }

    // 2026-09-16 诊断信息随扫描结果返回(UI对话框展示"跳过N个"等)
    final notes = <String>[
      if (truncated) '候选超过$maxCandidates个已截断',
      if (parseFailures.isNotEmpty) '跳过 ${parseFailures.length} 个无法解析的目录',
    ];
    _lastScanNote = notes.isEmpty ? null : notes.join('；');
    return List.unmodifiable(_candidates);
  }

  /// 最近一次扫描的诊断说明(无则null，UI展示"跳过N个"等)
  String? get lastScanNote => _lastScanNote;
  String? _lastScanNote;

  /// 安装候选(勾选后逐个调用；来源标记为 github:owner/repo)
  Future<SkillMeta> installCandidate(
    GitHubSkillCandidate candidate,
    String owner,
    String repo,
  ) {
    return _storage.importFromDirectory(
      candidate.dir,
      source: 'github:$owner/$repo',
      sourceUrl: 'https://github.com/$owner/$repo',
    );
  }

  /// 2026-09-16 P3-2 从源更新单个技能：
  /// 重新拉取仓库 → 按name匹配候选 → 覆盖安装(沿用既有覆盖语义：
  /// 保留创建时间与启用态) → 比对更新前后SKILL.md文本判断有无变化。
  /// 无sha本地记录可比(不为此做DB迁移)，重装即更新、内容比对做反馈。
  /// 返回 (skill: 更新后的元数据, changed: 文本是否有变化)
  Future<({SkillMeta skill, bool changed})> updateSkillFromSource(
    SkillMeta skill,
  ) async {
    final source = skill.source;
    if (!source.startsWith('github:')) {
      throw SkillGitHubException('技能 "${skill.name}" 非 GitHub 来源，无法从源更新');
    }
    final parsed = parseRepoInput(source.substring('github:'.length));
    if (parsed == null) {
      throw SkillGitHubException('来源标记无法解析: $source');
    }

    final before = await _storage.readSkillMarkdown(skill.name);
    final candidates = await fetchCandidates(parsed.owner, parsed.repo);
    try {
      final matched = candidates
          .where((c) => c.parseResult.name == skill.name)
          .toList();
      if (matched.isEmpty) {
        throw SkillGitHubException('源仓库中已找不到技能 "${skill.name}"(可能已被上游移除或改名)');
      }
      final meta = await installCandidate(
        matched.first,
        parsed.owner,
        parsed.repo,
      );
      final after = await _storage.readSkillMarkdown(meta.name);
      return (skill: meta, changed: before.trim() != after.trim());
    } finally {
      await cleanup();
    }
  }

  /// 释放临时目录(拉取失败/安装完成/放弃时调用)
  Future<void> cleanup() async {
    _candidates = [];
    _lastScanNote = null;
    final dir = _tempDir;
    _tempDir = null;
    if (dir != null && dir.existsSync()) {
      try {
        await dir.delete(recursive: true);
      } catch (e) {
        pl.w('技能仓库临时目录清理失败: $e');
      }
    }
  }
}
