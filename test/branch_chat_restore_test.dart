// 0.1.4 备份的 branch_chat_history.json → unified 库导入链路验证
// 关键回归点：0.1.4 的消息 json 无 branchPath/parentMessageId(运行时
// 计算值不落库)——解析不得崩，导入后分支字段按单链回填可读。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suchat_lite/features/unified_chat/data/database/unified_chat_dao.dart';
import 'package:suchat_lite/features/unified_chat/data/database/unified_chat_ddl.dart';
import 'package:suchat_lite/features/unified_chat/data/database/unified_chat_db_init.dart';
import 'package:suchat_lite/features/unified_chat/data/models/branch_chat_export_data.dart';
import 'package:suchat_lite/features/unified_chat/data/services/branch_chat_importer.dart';

import 'fixtures/migration_ddl_current.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;
  late String dbPath;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('branch_import_test');
    dbPath = p.join(tmp.path, 'unified.db');
    // 测试路径覆盖：真实 Dao 单例链路指向临时库
    UnifiedChatDBInit.debugDatabasePath = dbPath;
  });

  tearDown(() {
    UnifiedChatDBInit.debugDatabasePath = null;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Database> buildV2DbWithSeeds() async {
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (d, v) async {
        for (final sql in kDdlCurrentStatements) {
          await d.execute(sql);
        }
        // 内置平台/搭档/MCP种子(导入器的平台映射依赖)
        await UnifiedChatDdl.initDefaultPlatforms(d);
        await UnifiedChatDdl.initDefaultPartners(d);
        await UnifiedChatDdl.initDefaultMcpServers(d);
      },
    );
  }

  test('0.1.4格式(无branchPath/parentMessageId)导入不崩且消息可读', () async {
    // ===== 按0.1.4导出格式构造备份json(消息无branchPath/parentMessageId)
    final legacyJson = {
      'sessions': [
        {
          'id': 101,
          'title': '旧分支会话A',
          'createTime': '2025-10-01T10:00:00.000',
          'updateTime': '2025-10-01T10:05:00.000',
          'llmSpec': {
            'platform': 'aliyun',
            'model': 'qwen3.8-max',
            'name': 'Qwen3.8-Max',
            'baseUrl': 'https://dashscope.aliyuncs.com',
            'modelType': 'cc',
          },
          'modelType': 'cc',
          'characterId': null,
          'messages': [
            {
              'messageId': 'm1',
              'role': 'user',
              'content': '你好',
              'createTime': '2025-10-01T10:00:00.000',
              'branchIndex': 0,
              'depth': 0,
              'promptTokens': 10,
              'completionTokens': 0,
              'totalTokens': 10,
            },
            {
              'messageId': 'm2',
              'role': 'assistant',
              'content': '你好！',
              'createTime': '2025-10-01T10:00:30.000',
              'reasoningContent': null,
              'branchIndex': 0,
              'depth': 1,
              'promptTokens': 10,
              'completionTokens': 5,
              'totalTokens': 15,
            },
          ],
        },
      ],
    };

    // ===== 解析(0.1.4格式不得崩) =====
    final data = BranchChatExportData.fromJson(
      json.decode(json.encode(legacyJson)) as Map<String, dynamic>,
    );
    expect(data.sessions.length, 1);
    expect(
      data.sessions.first.messages.first.branchPath,
      isNull,
      reason: '0.1.4格式无branchPath，解析后应为null而非抛异常',
    );

    // ===== 建库(带种子)+导入(真实Dao单例链路) =====
    final db = await buildV2DbWithSeeds();
    await db.close();

    final importer = BranchChatImporter();
    final result = await importer.importFromJson(legacyJson);
    expect(result.importedCount, 1, reason: '导入1个会话');
    expect(result.failedCount, 0, reason: '不应有失败: ${result.errors}');

    // ===== 会话与消息入库+回填断言 =====
    final dao = UnifiedChatDao();
    final convs = await dao.getConversations();
    expect(convs.map((c) => c.id), contains('migrated_101'));

    final reopened = await openDatabase(dbPath);
    final msgs = await reopened.query(
      UnifiedChatDdl.tableUnifiedChatMessage,
      where: 'conversation_id = ?',
      whereArgs: ['migrated_101'],
      orderBy: 'created_at ASC',
    );
    expect(msgs.length, 2);
    // 回填串链：首条depth=0 path='0'，次条挂首条之后
    expect(msgs[0]['branch_path'], '0');
    expect(
      msgs[1]['parent_id'],
      msgs[0]['id'],
      reason: '0.1.4数据无parent链，导入后应按单链重建',
    );
    expect(msgs[1]['branch_path'], '0/0');
    await reopened.close();
  });
}
