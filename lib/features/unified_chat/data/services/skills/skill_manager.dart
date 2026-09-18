import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../../core/utils/simple_tools.dart';
import '../../models/mcp_models.dart';
import '../../models/openai_request.dart';
import 'skill_storage_service.dart';

/// Agent Skills 管理器（P1-1/P1-2）
/// implements ChatToolProvider：把内置只读工具 read_skill 接入
/// service 的 provider 分发路由（canHandle），自动获得哨兵/耗时/
/// 卡片展示链路；同时提供 Level 1 技能清单文本构建（sendMessage 注入）
class SkillManager implements ChatToolProvider {
  // 单例
  static final SkillManager _instance = SkillManager._internal();
  factory SkillManager() => _instance;
  SkillManager._internal();

  final SkillStorageService _storage = SkillStorageService();

  static const String toolName = 'read_skill';

  /// 2026-09-16 发现性工具：列出全部启用技能的name+简介。清单注入语义
  /// 翻转后(默认搭档不再全量注入清单)，本工具是模型发现技能的唯一通道
  /// ——用户问"有哪些技能"或任务可能匹配未见技能时按需调用，token
  /// 成本从"每请求固定"变为"仅在需要发现时一次"
  static const String listToolName = 'read_skill_list';

  /// Level 1 清单字符预算与单条描述截断（PLAN 4.3）。
  /// 2026-09-16 曾两连改(4000→16000、写死→GetStorage可配+管理页设置
  /// 卡)——2026-09-18 语义翻转后回退：清单只来自搭档显式挂载(通常
  /// 几个~十几个，1-3K字符)，预算几乎触不到线；用户可配反而会误伤
  /// ("调小→挂了10个只列出8个"的困惑)。设置卡下架，预算退化为内部
  /// 防呆常量64000(≈290个满描述技能才触线，纯极端保护)；万一触线
  /// 清单尾部注明剩余数量并引导read_skill_list发现，模型可自纠；
  /// maxEnabledSkills=100为数量防呆
  static const int catalogBudget = 64000;
  static const int catalogDescriptionClip = 200;
  static const int maxEnabledSkills = 100;

  /// 2026-09-16 修复"SKILL.md被截断导致模型反复重读"(用户实测
  /// frontend-design 10KB+ 被 service 6000字符上限截断，模型不知道
  /// 如何续读就反复尝试其他工具)：read_skill 内置分页协议——
  /// 每页 _pageSize 字符(约4k token，中转安全线内)，结果末尾附
  /// 续读指引(offset参数)，模型可自助翻页拿到全文
  static const int pageSize = 16000;

  @override
  String get namespace => '';

  @override
  bool canHandle(String toolName) =>
      toolName == SkillManager.toolName ||
      toolName == SkillManager.listToolName;

  @override
  Future<void> ensureReady() async {
    // 技能是本地静态资源，无需懒初始化
  }

  /// 是否有启用技能(工具注入门禁：有技能才注入 read_skill/read_skill_list，
  /// 零技能时两者都省)。清单注入与工具注入已解耦——默认搭档无清单
  /// 也需要发现通道
  Future<bool> hasEnabledSkills() async {
    return (await _storage.getEnabledSkills()).isNotEmpty;
  }

  /// OpenAI function 工具定义。无启用技能时返回空（不向模型注入工具，
  /// 省下工具定义 token）；有技能时始终可调用（清单里才有具体技能名）
  @override
  List<OpenAITool> getTools() {
    return [
      OpenAITool.function(
        const OpenAIFunction(
          name: SkillManager.toolName,
          description:
              '读取已安装技能(Agent Skill)的完整说明文档。当任务与"可用技能"'
              '清单中的某个技能相关时，先调用本工具读取该技能的完整方法论，'
              '再按说明执行。SKILL.md 中提到的 references/xxx 等相对路径'
              '文件即位于该技能目录内——不带 file 的首次读取会在开头给出'
              '技能安装目录与全部附属文件清单：读参考内容按清单传 file；'
              '执行技能自带脚本(如 scripts/xxx.py)用安装目录拼绝对路径，'
              '无需使用shell搜索文件系统。'
              '长文档自动分页，按结果末尾的提示传 offset 续读即可。',
          parameters: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'skill': <String, dynamic>{
                'type': 'string',
                'description': '技能名称(见可用技能清单或read_skill_list结果)',
              },
              'file': <String, dynamic>{
                'type': 'string',
                'description':
                    '可选，技能附属文件的相对路径(如 references/xxx.md，'
                    '以首次读取开头列出的清单为准)；省略则读SKILL.md',
              },
              'offset': <String, dynamic>{
                'type': 'integer',
                'description': '可选，长文档续读起始位置(字符偏移)，按上次结果末尾提示传参',
              },
            },
            'required': <String>['skill'],
          },
        ),
      ),
      OpenAITool.function(
        const OpenAIFunction(
          name: SkillManager.listToolName,
          description:
              '列出全部可用技能的名称与简介(紧凑列表)。当用户询问你有哪些'
              '技能/能做什么，或当前任务可能匹配某个技能但"可用技能"清单'
              '中未见时，先调用本工具发现技能，再对目标技能调用 read_skill'
              '读取完整说明。列表较长时按结果末尾提示传 offset 翻页。',
          parameters: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'offset': <String, dynamic>{
                'type': 'integer',
                'description': '可选，列表续读起始位置(字符偏移)，按上次结果末尾提示传参',
              },
            },
            'required': <String>[],
          },
        ),
      ),
    ];
  }

  /// Level 1 技能清单文本（无可注入技能时返回 null，不注入）。
  /// 2026-09-16 语义翻转后本方法只被"显式挂载非空清单"的搭档调用
  /// (service侧门控)：[mountedSkillIds] 与启用技能取交集。
  /// 格式：`- name: description`，超出预算截断并注明剩余数量
  Future<String?> buildSkillCatalog({List<String>? mountedSkillIds}) async {
    var skills = await _storage.getEnabledSkills();
    // 2026-09-16 诊断日志(用户实测：GitHub新装技能回聊天页清单不见)：
    // 打印启用名单与挂载过滤前后数量，区分"DB读取不到"(安装链路bug)、
    // "挂载交集排除"(设计行为)、"预算截断"三种情况
    pl.i(
      '技能清单构建: 启用${skills.length}个'
      '${skills.map((s) => s.name).toList()}；'
      '搭档挂载过滤: ${mountedSkillIds ?? '未配置'}',
    );
    if (skills.isEmpty) return null;

    // 挂载交集
    if (mountedSkillIds != null) {
      final mounted = mountedSkillIds.toSet();
      skills = skills.where((s) => mounted.contains(s.name)).toList();
      if (skills.isEmpty) {
        pl.w('技能清单构建: 挂载交集为空，本轮不注入任何技能');
        return null;
      }
      pl.i(
        '技能清单构建: 挂载交集后${skills.length}个'
        '${skills.map((s) => s.name).toList()}',
      );
    }

    // 上限保护：超过 maxEnabledSkills 时按启用顺序截断
    final overflow = skills.length > maxEnabledSkills;
    if (overflow) skills = skills.sublist(0, maxEnabledSkills);

    final buffer = StringBuffer('## 可用技能\n');
    var budgetLeft = catalogBudget;
    var listed = 0;
    for (final s in skills) {
      final desc = (s.description == null || s.description!.isEmpty)
          ? '(无描述)'
          : (s.description!.length > catalogDescriptionClip
                ? '${s.description!.substring(0, catalogDescriptionClip)}…'
                : s.description!);
      final line = '- ${s.name}: $desc\n';
      if (line.length > budgetLeft) break;
      buffer.write(line);
      budgetLeft -= line.length;
      listed++;
    }

    final omitted = skills.length - listed;
    if (omitted > 0) {
      buffer.write('（预算所限另有 $omitted 个挂载技能未列出）\n');
    }

    buffer.write(
      '当任务与上述某技能相关时，先调用 read_skill 工具（参数 skill=技能名）'
      '读取完整说明，再按说明执行。'
      '本清单只含该搭档挂载的技能；用户询问其他技能，或任务可能匹配'
      '清单外的技能时，调用 read_skill_list 工具发现全部可用技能。\n',
    );
    return buffer.toString();
  }

  @override
  Future<ToolResult> handleToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    // 2026-09-16 发现性工具：全部启用技能的紧凑清单(name+截短描述)，
    // 挂载无关——发现性天然全局(清单注入只服务显式挂载的搭档)
    if (toolName == SkillManager.listToolName) {
      final offset = (arguments['offset'] as num?)?.toInt() ?? 0;
      final skills = await _storage.getEnabledSkills();
      if (skills.isEmpty) {
        return const ToolResult(
          content:
              '当前没有已启用的技能。'
              '可在"技能管理"页导入或从精选源安装。',
        );
      }
      final buffer = StringBuffer('共${skills.length}个技能：\n');
      for (final s in skills) {
        final desc = (s.description == null || s.description!.isEmpty)
            ? '(无描述)'
            : (s.description!.length > catalogDescriptionClip
                  ? '${s.description!.substring(0, catalogDescriptionClip)}…'
                  : s.description!);
        buffer.write('- ${s.name}: $desc\n');
      }
      return ToolResult(content: _paginate(buffer.toString(), offset));
    }

    final skill = (arguments['skill'] as String?)?.trim() ?? '';
    if (skill.isEmpty) {
      return const ToolResult(content: '参数错误：缺少 skill(技能名称)');
    }

    final enabled = await _storage.getEnabledSkills();
    if (!enabled.any((s) => s.name == skill)) {
      final all = await _storage.getAllSkills();
      final exists = all.any((s) => s.name == skill);
      return ToolResult(
        content: exists
            ? '技能 "$skill" 存在但已停用，无法读取。'
            : '技能 "$skill" 不存在。可用技能: '
                  '${enabled.map((s) => s.name).join(', ').isEmpty ? '(无)' : enabled.map((s) => s.name).join(', ')}',
      );
    }

    final fileArg = (arguments['file'] as String?)?.trim();
    // 续读偏移(长文档分页协议)
    final offset = (arguments['offset'] as num?)?.toInt() ?? 0;
    try {
      if (fileArg == null || fileArg.isEmpty) {
        // 2026-09-16 附属文件发现：首页开头附清单——SKILL.md正文提到的
        // 相对路径(references/xxx等)可直接对应到技能目录内文件，模型
        // 不再误用shell去系统目录搜索(用户实测glmv-stock-analyzer案例)
        final md = await _storage.readSkillMarkdown(skill);
        final page = _paginate(md.trim().isEmpty ? '(技能文档为空)' : md, offset);
        if (offset > 0) return ToolResult(content: page);
        final listing = await _auxListing(skill);
        return ToolResult(
          content: listing == null ? page : '$listing\n\n----\n\n$page',
        );
      }

      // 附属文件：先按清单校验(分隔符归一)，不存在时直接返回可用路径
      // 引导而非笼统报错(模型能自纠传参)
      final aux = await _storage.listAuxFiles(skill);
      final auxNames = aux.map((e) => e.replaceAll('\\', '/')).toList();
      final normalized = fileArg.replaceAll('\\', '/');
      if (!auxNames.contains(normalized)) {
        return ToolResult(content: _auxNotFound(skill, normalized, auxNames));
      }

      // 文本扩展名读内容，二进制标注大小
      final ext = p.extension(normalized).toLowerCase();
      const textExts = {
        '.md',
        '.txt',
        '.json',
        '.yaml',
        '.yml',
        '.csv',
        '.html',
        '.css',
        '.js',
        '.ts',
        '.py',
        '.sh',
        '.dart',
        '.xml',
        '.toml',
        '.ini',
      };
      if (!textExts.contains(ext)) {
        final meta = await _storage.getSkill(skill);
        return ToolResult(
          content:
              '附属文件 "$fileArg" 为二进制或非文本类型，已省略内容'
              '(${meta?.fileSize ?? 0} 字节为技能总大小)',
        );
      }
      final content = await _storage.readAuxFile(skill, normalized);
      return ToolResult(
        content: _paginate(content.trim().isEmpty ? '(文件为空)' : content, offset),
      );
    } on SkillImportException catch (e) {
      // 存储层的可读错误(不存在/非法路径等)直接回给模型
      return ToolResult(content: e.message);
    } on FileSystemException catch (e) {
      return ToolResult(content: '读取技能文件失败: ${e.message}');
    }
  }

  /// 附属文件路径清单文本(null=无附属文件，不加前缀块)。
  /// 2026-09-16 八十三：清单让模型定位file参数取值(读参考文件场景)；
  /// 八十四补充安装目录绝对路径——SKILL.md让执行scripts/xxx.py时
  /// 模型拿着相对路径没有基目录，只能shell遍历磁盘找技能目录(实测
  /// Qwen读完后立刻Get-ChildItem扫C:/D:/USERPROFILE)；路径透明+
  /// shell审批兜底与Claude Code官方(skills装在~/.claude/skills对
  /// agent可见)一致
  /// 附属文件清单展示上限：2026-09-16 用户质疑"需要的文件恰好在未
  /// 列出部分就无法处理"——原20截断确实存在该边缘(泛引用场景SKILL.md
  /// 未点名文件时清单是唯一线索)。改为与存储限额maxAuxFiles(200)对齐
  /// 即全量列出：路径行极短(200个≈6KB)，首页前缀最坏挤占正文尾部
  /// 2KB由分页续读兜底，可接受
  static const int _auxListLimit = 200;

  Future<String?> _auxListing(String skill) async {
    final names = (await _storage.listAuxFiles(
      skill,
    )).map((e) => e.replaceAll('\\', '/')).toList();
    if (names.isEmpty) return null;
    final meta = await _storage.getSkill(skill);
    final root = meta?.dirPath ?? '(未知)';
    return '[技能安装目录: $root——SKILL.md要求执行其中的脚本(如'
        'scripts/xxx.py)时，直接用该绝对路径调用(可另经shell工具传'
        'working_directory)，无需搜索文件系统。]\n'
        '[本技能附属文件 ${names.length} 个——读取参考内容请再次调用'
        'read_skill，传file=以下任一相对路径]\n'
        '${_renderAuxListing(names)}';
  }

  /// file参数传了不存在路径时的引导错误：附可用清单让模型自纠
  String _auxNotFound(String skill, String fileArg, List<String> names) {
    if (names.isEmpty) {
      return '技能 "$skill" 没有附属文件，无法读取file="$fileArg"。'
          '省略file参数读取SKILL.md即可。';
    }
    return '附属文件 "$fileArg" 不存在。可用文件如下(相对路径，'
        '直接作为file参数传入)：\n${_renderAuxListing(names)}';
  }

  String _renderAuxListing(List<String> names) {
    final shown = names.take(_auxListLimit).join('\n');
    final more = names.length > _auxListLimit
        ? '\n(另有 ${names.length - _auxListLimit} 个未列出)'
        : '';
    return '$shown$more';
  }

  /// 长文档分页：从 offset 起切 pageSize 字符(UTF-16代理对保护)，
  /// 有剩余时在末尾附明确的续读指引(防止模型截断后反复换工具重读)
  String _paginate(String full, int offset) {
    final total = full.length;
    var start = offset.clamp(0, total);
    var end = (start + pageSize).clamp(0, total);
    // 截断点落在代理对中间则回退一位
    if (end < total && end > start) {
      final lastUnit = full.codeUnitAt(end - 1);
      if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) end--;
    }
    final page = full.substring(start, end);
    if (end >= total) {
      // 已到最后：无需附加提示(首读即全文时也不打扰)
      return start == 0 ? page : '$page\n\n[文档结束，共$total字符]';
    }
    return '$page\n\n[文档共$total字符，当前显示 $start-$end。'
        '继续读取请再次调用 read_skill，传 offset=$end（其余参数不变）]';
  }
}
