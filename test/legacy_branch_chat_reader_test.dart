// 旧版(0.1.4)分支聊天ObjectBox读取器往返测试
// 用legacy实体造一个模拟0.1.4结构的数据目录 → LegacyBranchChatReader
// 读取 → 断言转换正确(branchPath可信度校验/parent链/枚举名剥前缀/
// references解码/时间保留)。
// 同时覆盖备份导入的时间保留回归：updateTime不得被统计刷新覆盖。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:suchat_lite/core/services/legacy_branch_chat_reader.dart';
import 'package:suchat_lite/core/services/legacy_objectbox/branch_chat_message.dart';
import 'package:suchat_lite/core/services/legacy_objectbox/branch_chat_session.dart';
import 'package:suchat_lite/features/unified_chat/data/database/unified_chat_dao.dart';
import 'package:suchat_lite/features/unified_chat/data/database/unified_chat_db_init.dart';
import 'package:suchat_lite/features/unified_chat/data/services/branch_chat_importer.dart';

void main() {
  late Directory tmp;
  late Directory obDir;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('legacy_ob_test');
    // 与真实旧版结构一致：legacyRoot/DB/objectbox/branch_chat
    obDir = Directory(p.join(tmp.path, 'DB', 'objectbox', 'branch_chat'))
      ..createSync(recursive: true);
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('旧ObjectBox数据读取转换：往返一致+branchPath校验+时间保留', () async {
    final store = LegacyBranchChatReader.openForTest(obDir.path);
    try {
      // ===== 造0.1.4风格数据 =====
      final session = BranchChatSession(
        title: '旧分支会话',
        createTime: DateTime(2025, 9, 1, 10),
        updateTime: DateTime(2025, 9, 2, 18, 30),
        llmSpecJson:
            '{"platform":"aliyun","model":"qwen-max","name":"Qwen-Max",'
            '"baseUrl":"https://dashscope.aliyuncs.com","modelType":"cc"}',
        modelTypeStr: 'LLModelType.cc', // enum toString带前缀
      );
      store.box<BranchChatSession>().put(session);

      final m0 = BranchChatMessage(
        messageId: 'lm1',
        role: 'user',
        content: '你好',
        createTime: DateTime(2025, 9, 1, 10, 1),
        branchIndex: 0,
        depth: 0,
        branchPath: '0',
      );
      final m1 = BranchChatMessage(
        messageId: 'lm2',
        role: 'assistant',
        content: '你好！',
        createTime: DateTime(2025, 9, 1, 10, 2),
        branchIndex: 0,
        depth: 1,
        // 0.1.4未可靠维护的场景：path默认'0'与depth不匹配→应判不可信
        branchPath: '0',
      );
      final m2 = BranchChatMessage(
        messageId: 'lm3',
        role: 'assistant',
        content: '换个说法：你好呀',
        createTime: DateTime(2025, 9, 1, 10, 3),
        branchIndex: 1,
        depth: 1,
        branchPath: '0/1', // 可信路径
      );
      final box = store.box<BranchChatMessage>();
      // 先落库拿id，再建关系(ToOne需目标id有效)，最后重put保存关系
      box.put(m0);
      box.put(m1);
      box.put(m2);
      m0.session.target = session;
      m1.session.target = session;
      m2.session.target = session;
      m2.parent.target = m1;
      box.put(m0);
      box.put(m1);
      box.put(m2);
      // 关联回填后重取
      final reloaded = store.box<BranchChatSession>().get(session.id)!;
      expect(reloaded.messages.length, 3);

      // 同目录不允许第二个Store实例：先关写侧再走读取器
      store.close();

      // ===== 读取转换 =====
      final errors = <String>[];
      final sessions = await LegacyBranchChatReader.read(tmp, errors: errors);
      expect(sessions.length, 1);
      expect(errors, isEmpty);

      final export = sessions.first;
      expect(export.title, '旧分支会话');
      expect(export.createTime, DateTime(2025, 9, 1, 10));
      expect(export.updateTime, DateTime(2025, 9, 2, 18, 30));
      expect(export.modelType, 'cc', reason: 'LLModelType.前缀应被剥离');
      expect(export.llmSpec['platform'], 'aliyun');
      expect(export.messages.length, reloaded.messages.length);

      final byId = {for (final m in export.messages) m.messageId: m};
      // 可信路径保留+parent链
      expect(byId['lm3']!.branchPath, '0/1');
      expect(byId['lm3']!.parentMessageId, 'lm2');
      // 不可信路径置空(走导入侧单链回填)
      expect(byId['lm2']!.branchPath, isNull);
    } finally {
      store.close();
    }
  });

  test('备份导入时间保留回归：导入后updateTime为备份值而非now', () async {
    UnifiedChatDBInit.debugDatabasePath = p.join(tmp.path, 'unified.db');
    try {
      // 直接用上一用例同构的会话json走导入链
      final legacyJson = {
        'sessions': [
          {
            'id': 900,
            'title': '时间保留会话',
            'createTime': '2025-09-01T10:00:00.000',
            'updateTime': '2025-09-02T18:30:00.000',
            'llmSpec': {
              'platform': 'aliyun',
              'model': 'qwen-max',
              'name': 'Qwen-Max',
              'modelType': 'cc',
            },
            'modelType': 'cc',
            'messages': [
              {
                'messageId': 'tm1',
                'role': 'user',
                'content': 'hi',
                'createTime': '2025-09-01T10:00:00.000',
                'branchIndex': 0,
                'depth': 0,
              },
              {
                'messageId': 'tm2',
                'role': 'assistant',
                'content': 'hello',
                'createTime': '2025-09-01T10:00:30.000',
                'branchIndex': 0,
                'depth': 1,
              },
            ],
          },
        ],
      };

      final result = await BranchChatImporter().importFromJson(legacyJson);
      expect(result.importedCount, 1);

      final convId = 'migrated_900';
      // 时间对齐：updateTime应为备份值(误差<5秒容忍统计精确性)
      final convs = await UnifiedChatDao().getConversations();
      final conv = convs.where((c) => c.id == convId).firstOrNull;
      expect(conv, isNotNull);
      final diff = conv!.updatedAt.difference(DateTime(2025, 9, 2, 18, 30));
      expect(
        diff.inSeconds.abs() < 5,
        isTrue,
        reason:
            '导入后会话updateTime应为备份值(2025-09-02 18:30)，'
            '实际: ${conv.updatedAt}',
      );
    } finally {
      UnifiedChatDBInit.debugDatabasePath = null;
    }
  });
}
