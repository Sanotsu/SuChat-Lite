// 旧版(0.1.4)分支聊天 ObjectBox 数据读取器
// 仅供 UpgradeMigrator 直接升级迁移使用：打开旧库(只读查询)，
// 把会话/消息转为新版备份导出格式(BranchChatSessionExport)，
// 之后交给 BranchChatImporter 复用既有导入链路(平台/搭档映射、
// 幂等判重、分支回填)。
//
// 2026-10-12 最小集成：ObjectBox 依赖仅服务本读取器与legacy实体，
// 业务代码禁止使用；迁移率稳定后可随实体一起整体移除。
// 实体类名(BranchChatSession/BranchChatMessage/CharacterCard)与
// 0.1.4一致——ObjectBox的model entity name绑定类名，不可改。
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/unified_chat/data/models/branch_chat_export_data.dart';
import '../storage/objectbox.g.dart';
import 'legacy_objectbox/branch_chat_message.dart';
import 'legacy_objectbox/branch_chat_session.dart';

class LegacyBranchChatReader {
  LegacyBranchChatReader._();

  /// 旧ObjectBox库目录(legacyRoot/DB/objectbox/branch_chat)是否存在数据
  static bool hasData(Directory legacyRoot) {
    final dir = Directory(p.join(legacyRoot.path, 'DB/objectbox/branch_chat'));
    if (!dir.existsSync()) return false;
    try {
      return dir
          .listSync(followLinks: false)
          .any((e) => e.path.endsWith('.mdb'));
    } catch (_) {
      return false;
    }
  }

  /// 读取旧库并转换为导出格式。
  /// [errors] 收集单会话转换失败原因(不中断整体)。
  static Future<List<BranchChatSessionExport>> read(
    Directory legacyRoot, {
    List<String>? errors,
  }) async {
    final errList = errors ?? <String>[];
    final dir = Directory(p.join(legacyRoot.path, 'DB/objectbox/branch_chat'));

    // objectbox 5.x：Store构造在flutter与桌面测试环境通用
    // (native库由objectbox_flutter_libs提供)
    final store = Store(getObjectBoxModel(), directory: dir.path);
    try {
      final sessionBox = store.box<BranchChatSession>();
      final result = <BranchChatSessionExport>[];

      for (final s in sessionBox.getAll()) {
        try {
          result.add(_convertSession(s, errList));
        } catch (e) {
          errList.add('会话[${s.title}]转换失败: $e');
        }
      }
      return result;
    } finally {
      // 只读用途：close不落任何新数据；旧库文件仍留在封存目录兜底
      store.close();
    }
  }

  /// 测试用：直接对指定目录打开Store
  static Store openForTest(String directory) =>
      Store(getObjectBoxModel(), directory: directory);

  static BranchChatSessionExport _convertSession(
    BranchChatSession s,
    List<String> errors,
  ) {
    Map<String, dynamic> spec = {};
    try {
      if (s.llmSpecJson != null && s.llmSpecJson!.isNotEmpty) {
        spec = jsonDecode(s.llmSpecJson!) as Map<String, dynamic>;
      }
    } catch (e) {
      errors.add('会话[${s.title}]llmSpec解析失败: $e');
    }

    return BranchChatSessionExport(
      id: s.id,
      title: s.title,
      createTime: s.createTime,
      updateTime: s.updateTime,
      llmSpec: spec,
      // 0.1.4存储的是enum toString('LLModelType.cc')——备份json用裸名
      modelType: (s.modelTypeStr ?? 'cc').split('.').last,
      characterId: s.characterId,
      messages: s.messages.map(_convertMessage).toList(),
    );
  }

  static BranchChatMessageExport _convertMessage(BranchChatMessage m) {
    // 0.1.4运行时对branchPath的维护不可靠(部分消息只有默认'0')：
    // 仅当路径段数与depth匹配且各段为数字时视为可信，否则置空走
    // 导入侧单链回填
    final pathOk = _isTrustworthyPath(m.branchPath, m.depth);

    return BranchChatMessageExport(
      messageId: m.messageId,
      role: m.role,
      content: m.content,
      createTime: m.createTime,
      reasoningContent: m.reasoningContent,
      thinkingDuration: m.thinkingDuration,
      contentVoicePath: m.contentVoicePath,
      imagesUrl: m.imagesUrl,
      videosUrl: m.videosUrl,
      audiosUrl: m.audiosUrl,
      omniAudioVoice: m.omniAudioVoice,
      references: m.decodeReferences(),
      promptTokens: m.promptTokens,
      completionTokens: m.completionTokens,
      totalTokens: m.totalTokens,
      modelLabel: m.modelLabel,
      branchIndex: m.branchIndex,
      depth: m.depth,
      branchPath: pathOk ? m.branchPath : null,
      parentMessageId: pathOk ? m.parent.target?.messageId : null,
      characterId: m.characterId,
    );
  }

  static bool _isTrustworthyPath(String path, int depth) {
    if (path.isEmpty) return false;
    final segments = path.split('/');
    if (segments.length != depth + 1) return false;
    return segments.every((seg) => int.tryParse(seg) != null);
  }
}
