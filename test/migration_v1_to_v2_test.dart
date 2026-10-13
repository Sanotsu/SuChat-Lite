// 0.1.4(v1) → 0.1.5(v2) 合并迁移验证测试
// 用 0.1.4 真实 DDL(748e2ef)建 v1 库 → 跑生产同款升级回调 → 断言
// 数据存活/回填正确/最终结构与当前 DDL 逐表一致。
// 改动迁移逻辑后本地 `flutter test` 秒级验证，无需打包上真机。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suchat_lite/features/unified_chat/data/database/unified_chat_db_init.dart';

import 'fixtures/migration_ddl_current.dart';
import 'fixtures/migration_ddl_v1.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;
  late String v1Path;
  late String refPath;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('migration_test');
    v1Path = p.join(tmp.path, 'v1.db');
    refPath = p.join(tmp.path, 'ref.db');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// 按 v1(0.1.4) DDL 建库并种入样例数据
  Future<void> buildV1Db() async {
    final db = await openDatabase(
      v1Path,
      version: 1,
      onCreate: (d, v) async {
        for (final sql in kDdlV10Statements) {
          await d.execute(sql);
        }
      },
    );

    // 平台 + 模型（0.1.4 结构，无 supports_image_input/video_gen_prefix）
    await db.insert('suchat_unified_platform_spec', {
      'id': 'aliyun',
      'display_name': '阿里百炼',
      'host_url': 'https://dashscope.aliyuncs.com',
      'cc_prefix': '/compatible-mode/v1/chat/completions',
      'img_gen_prefix': '/api/v1/services/aigc/text2image/image-synthesis',
      'is_built_in': 1,
      'is_active': 1,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
    });
    await db.insert('suchat_unified_model_spec', {
      'id': 'qwen3.8-max',
      'platform_id': 'aliyun',
      'model_name': 'qwen3.8-max',
      'display_name': 'Qwen3.8-Max',
      'model_type': 'cc',
      'supports_thinking': 1,
      'supports_vision': 0,
      'supports_tool_calling': 1,
      'is_built_in': 1,
      'is_active': 1,
      'is_favorite': 0,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
    });

    // 内置搭档（0.1.4：系统提示词列名是prompt，无角色卡列/skill_ids，
    // 参数是老默认值6）
    await db.insert('suchat_unified_chat_partner', {
      'id': 'partner-builtin-1',
      'name': '测试搭档',
      'prompt': 'you are helpful',
      'context_message_length': 6,
      'temperature': 0.7,
      'is_built_in': 1,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
    });

    // 会话 + 两条消息（线性历史，供分支回填）
    await db.insert('suchat_unified_conversation', {
      'id': 'conv-1',
      'title': '旧会话',
      'model_id': 'qwen3.8-max',
      'platform_id': 'aliyun',
      'partner_id': 'partner-builtin-1',
      'system_prompt': null,
      'temperature': null,
      'max_tokens': 2048,
      'top_p': null,
      'frequency_penalty': null,
      'presence_penalty': null,
      'context_message_length': 10,
      'is_stream': 1,
      'message_count': 2,
      'total_tokens': 100,
      'total_cost': 0.01,
      'is_pinned': 0,
      'is_archived': 0,
      'created_at': 1700000001000,
      'updated_at': 1700000002000,
    });
    await db.insert('suchat_unified_chat_message', {
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'role': 'user',
      'content': '你好',
      'created_at': 1700000001000,
      'updated_at': 1700000001000,
    });
    await db.insert('suchat_unified_chat_message', {
      'id': 'msg-2',
      'conversation_id': 'conv-1',
      'role': 'assistant',
      'content': '你好！有什么可以帮你？',
      'created_at': 1700000002000,
      'updated_at': 1700000002000,
    });

    await db.close();
  }

  /// 目标结构库（当前 DDL 直建，作为列集合对照基准）
  Future<Database> buildRefDb() {
    return openDatabase(
      refPath,
      version: 1,
      onCreate: (d, v) async {
        for (final sql in kDdlCurrentStatements) {
          await d.execute(sql);
        }
      },
    );
  }

  Future<Map<String, Set<String>>> tableColumns(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    final result = <String, Set<String>>{};
    for (final row in tables) {
      final name = row['name'] as String;
      final cols = await db.rawQuery('PRAGMA table_info($name)');
      result[name] = cols.map((c) => c['name'] as String).toSet();
    }
    return result;
  }

  test('v1 库经合并迁移后：迁移无异常、数据存活、结构与当前DDL一致', () async {
    await buildV1Db();

    // 生产同款路径：openDatabase version 1→2 触发 onUpgrade
    final upgraded = await openDatabase(
      v1Path,
      version: 2,
      onUpgrade: UnifiedChatDBInit.runUpgradeForVerification,
    );

    // ---- 数据存活 ----
    final convCount = Sqflite.firstIntValue(
      await upgraded.rawQuery(
        'SELECT COUNT(*) FROM suchat_unified_conversation',
      ),
    );
    expect(convCount, 1, reason: '会话数据须在(v4重建表后保留)');

    final msgs = await upgraded.query(
      'suchat_unified_chat_message',
      orderBy: 'created_at ASC',
    );
    expect(msgs.length, 2, reason: '消息数据须在');
    // 分支回填：线性历史串成单链(path格式 首条'0'，后续'父path/0')
    expect(msgs[0]['depth'], 0, reason: '首条消息depth=0');
    expect(msgs[0]['branch_path'], '0', reason: '首条消息branch_path');
    expect(msgs[1]['parent_id'], 'msg-1', reason: '第二条消息挂在首条之后');
    expect(msgs[1]['depth'], 1, reason: '第二条消息depth=1');
    expect(msgs[1]['branch_path'], '0/0', reason: '第二条消息branch_path');

    // ---- 补列生效 ----
    final modelCols = (await tableColumns(
      upgraded,
    ))['suchat_unified_model_spec']!;
    expect(
      modelCols.contains('supports_image_input'),
      true,
      reason: 'model_spec须补supports_image_input(否则模型种子INSERT崩)',
    );
    final platformCols = (await tableColumns(
      upgraded,
    ))['suchat_unified_platform_spec']!;
    expect(
      platformCols.contains('video_gen_prefix'),
      true,
      reason: 'platform_spec须补video_gen_prefix(否则OpenRouter种子INSERT崩)',
    );

    // ---- mcp_server：v7按当前DDL建表，扩展列齐+内置种子在 ----
    final mcpCols = (await tableColumns(
      upgraded,
    ))['suchat_unified_mcp_server']!;
    for (final c in [
      'is_search_source',
      'approval_required',
      'tools_cache',
      'oauth_client_id',
      'oauth_scopes',
    ]) {
      expect(mcpCols.contains(c), true, reason: 'mcp_server缺列$c');
    }
    final mcpCount = Sqflite.firstIntValue(
      await upgraded.rawQuery('SELECT COUNT(*) FROM suchat_unified_mcp_server'),
    );
    expect(mcpCount, greaterThanOrEqualTo(3), reason: '内置MCP种子须在');

    // ---- 内置模型/平台种子 ----
    final mimoExists = Sqflite.firstIntValue(
      await upgraded.rawQuery(
        "SELECT COUNT(*) FROM suchat_unified_model_spec WHERE platform_id='mimo'",
      ),
    );
    expect(mimoExists, greaterThan(0), reason: 'MiMo模型种子须在');
    final orExists = Sqflite.firstIntValue(
      await upgraded.rawQuery(
        "SELECT COUNT(*) FROM suchat_unified_platform_spec WHERE id='openrouter'",
      ),
    );
    expect(orExists, 1, reason: 'OpenRouter平台种子须在');

    // ---- 内置搭档参数清空(v4语义) ----
    final partner = await upgraded.query(
      'suchat_unified_chat_partner',
      where: 'id = ?',
      whereArgs: ['partner-builtin-1'],
    );
    expect(
      partner.first['context_message_length'],
      isNull,
      reason: '内置搭档context_message_length应清NULL',
    );
    expect(
      partner.first['temperature'],
      isNull,
      reason: '内置搭档temperature应清NULL',
    );
    expect(
      partner.first['skill_ids'],
      isNull,
      reason: '搭档skill_ids列须存在且默认NULL',
    );

    // ---- 结构与当前DDL逐表一致 ----
    final actual = await tableColumns(upgraded);
    final ref = await buildRefDb();
    final expected = await tableColumns(ref);

    expect(
      actual.keys.toSet(),
      expected.keys.toSet(),
      reason: '迁移后表集合应与当前DDL一致',
    );
    for (final t in expected.keys) {
      expect(actual[t], expected[t], reason: '表 $t 的列集合与当前DDL不一致');
    }

    await upgraded.close();
    await ref.close();
  });
}
