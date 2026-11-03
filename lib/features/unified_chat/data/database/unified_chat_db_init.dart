// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/storage/db_config.dart';
import '../../../../core/utils/get_dir.dart';
import '../models/unified_platform_spec.dart';
import 'unified_chat_ddl.dart';

class UnifiedChatDBInit {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final UnifiedChatDBInit _dbInit = UnifiedChatDBInit._createInstance();
  // 构造函数，返回单例
  factory UnifiedChatDBInit() => _dbInit;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  UnifiedChatDBInit._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  /// 关闭库连接并清空缓存(下次getter重开)。
  /// 2026-10-12 迁移器覆盖复制库文件前调用：Windows下目标文件被
  /// 本进程打开时复制会 errno 32 失败，必须先关闭
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }

  // 仅供测试覆盖库路径(flutter test)：生产代码勿读写
  @visibleForTesting
  static String? debugDatabasePath;

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 如果是桌面端（Windows/Linux/macOS），初始化 FFI
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 在任何平台操作之前首先初始化FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi; // 设置全局 databaseFactory
    }

    // 自定义的sqlite数据库文件保存的目录
    // (测试可经debugDatabasePath整体短路真实目录解析——测试环境无
    //  path_provider平台通道)
    if (debugDatabasePath != null) {
      final db = await openDatabase(
        debugDatabasePath!,
        version: 2,
        onCreate: _createDb,
        onUpgrade: _upgradeDb,
      );
      await UnifiedChatDdl.initDefaultMcpServers(db);
      dbFilePath = debugDatabasePath!;
      return db;
    }
    Directory directory = await getSqliteDbDir();
    String path = "${directory.path}/${DBInitConfig.chatDbName}";

    print("初始化 Chat DB sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var db = await openDatabase(
      path,
      // 2026-09-18 升级链归一：0.1.5开发期按功能迭代累积的v2~v14共13个
      // 中间版本从未发布，真实用户没有也不需要这些中间态——线上存量库
      // 只有0.1.4的v1。版本号归一为2，全部迁移内容合并进_upgradeV1ToV2
      // 单方法一次执行，0.1.4→0.1.5即单纯的1个版本数据库升级。
      // 0.1.5发布后的新功能再从v2起追加增量迁移
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );

    // 2026-09-12 内置MCP种子每次启动幂等补种：原本种子只随onCreate/
    // onUpgrade执行，后续往BUILD_IN_MCP_SERVERS加新源时存量库拿不到
    // (库版本没变不触发升级)。ConflictAlgorithm.ignore仅补缺不覆盖
    // 用户修改，6行batch开销可忽略
    await UnifiedChatDdl.initDefaultMcpServers(db);

    dbFilePath = path;
    return db;
  }

  // 创建数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");

    /// 创建表
    await db.transaction((txn) async {
      txn.execute(UnifiedChatDdl.ddlForUnifiedPlatformSpec);
      txn.execute(UnifiedChatDdl.ddlForUnifiedModelSpec);
      txn.execute(UnifiedChatDdl.ddlForUnifiedChatMessage);
      txn.execute(UnifiedChatDdl.ddlForUnifiedConversation);
      txn.execute(UnifiedChatDdl.ddlForUnifiedApiKey);
      txn.execute(UnifiedChatDdl.ddlForUnifiedChatPartner);
      txn.execute(UnifiedChatDdl.ddlForTranslationHistory);
      txn.execute(UnifiedChatDdl.ddlIndexTranslationHistory);
      txn.execute(UnifiedChatDdl.ddlForUnifiedMcpServer);
      txn.execute(UnifiedChatDdl.ddlForUnifiedSkill);

      // 创建一些索引来提高查询性能
      await _createUnifiedChatIndex(txn);
    });

    /// 初始化默认值
    await UnifiedChatDdl.initDefaultPlatforms(db);
    await UnifiedChatDdl.initDefaultPartners(db);
    await UnifiedChatDdl.initDefaultMcpServers(db);
  }

  // 数据库升级
  // 2026-09-18 升级链归一：0.1.5开发期按功能迭代累积的v2~v14共13个
  // 中间版本从未发布，真实用户没有也不需要这些中间态——线上存量库
  // 只有0.1.4的v1。版本号归一为2，全部迁移内容合并进_upgradeV1ToV2
  // 单方法一次执行，0.1.4→0.1.5即单纯的1个版本数据库升级。
  // 注意：开发期装有v2~v14中间版本的设备库version>2会触发downgrade
  // 保护报错，请卸载重装
  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    print("Chat 数据库升级 _upgradeDb 从 $oldVersion 到 $newVersion");

    if (oldVersion < 2) {
      await _upgradeV1ToV2(db);
    }
  }

  /// 0.1.4(v1) → 0.1.5(v2) 全量迁移。
  /// 分段注释保留原开发期v2~v14的历史背景；步骤顺序即原递进链顺序，
  /// 后步依赖前步(如会话表重建依赖分支列的添加)
  Future<void> _upgradeV1ToV2(Database db) async {
    // ===== 表结构补齐(2026-09-18)：0.1.4发布后onCreate DDL新增的列，
    // 存量库须先补齐再执行后续任何种子插入(否则模型/平台种子INSERT
    // 带新列直接报no column named)。经全表DDL自动比对确认仅这两列，
    // 其余差异均由下方各分段步骤覆盖
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedModelSpec} '
      'ADD COLUMN supports_image_input INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedPlatformSpec} '
      'ADD COLUMN video_gen_prefix TEXT',
    );

    // ===== 清理已停服的内置平台残留数据(原v2)：零一万物/无问芯穹，
    // 会话/消息历史保留不动(模型名/平台名是文本快照，仅不可再续聊)
    const deadPlatforms = ['lingyiwanwu', 'infini'];
    final placeholders = List.filled(deadPlatforms.length, '?').join(',');

    await db.delete(
      UnifiedChatDdl.tableUnifiedApiKey,
      where: 'platform_id IN ($placeholders)',
      whereArgs: deadPlatforms,
    );
    await db.delete(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: 'platform_id IN ($placeholders)',
      whereArgs: deadPlatforms,
    );
    await db.delete(
      UnifiedChatDdl.tableUnifiedPlatformSpec,
      where: 'id IN ($placeholders)',
      whereArgs: deadPlatforms,
    );

    // ===== 消息表分支字段+会话表当前分支路径(原v2，SQLite加列必须逐条)
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatMessage} ADD COLUMN parent_id TEXT',
    );
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatMessage} '
      'ADD COLUMN branch_index INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatMessage} '
      'ADD COLUMN depth INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatMessage} '
      "ADD COLUMN branch_path TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedConversation} '
      'ADD COLUMN current_branch_path TEXT',
    );

    // ===== 搭档表合并角色卡系统(原v2)
    const partnerColumns = [
      'description TEXT',
      'personality TEXT',
      'scenario TEXT',
      'first_message TEXT',
      'example_dialogue TEXT',
      'tags TEXT',
      'preferred_model_id TEXT',
      'background TEXT',
      'background_opacity REAL',
    ];
    for (final col in partnerColumns) {
      await db.execute(
        'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatPartner} ADD COLUMN $col',
      );
    }

    // ===== 分支索引(原v2)
    await db.execute(
      'CREATE INDEX idx_messages_parent_id ON '
      '${UnifiedChatDdl.tableUnifiedChatMessage} (conversation_id, parent_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_branch_path ON '
      '${UnifiedChatDdl.tableUnifiedChatMessage} (conversation_id, branch_path)',
    );

    // ===== 回填存量消息为单链分支(原v2)：v1的消息是线性序列，
    // 按会话分组、创建时间排序，非system消息串成一条单链
    await _backfillBranchColumns(db);

    // ===== 翻译历史表(原v3，2026-09-03快速翻译改造)
    await db.execute(UnifiedChatDdl.ddlForTranslationHistory);
    await db.execute(UnifiedChatDdl.ddlIndexTranslationHistory);
    try {
      await db.execute(
        'ALTER TABLE ${UnifiedChatDdl.tableTranslationHistory} ADD COLUMN audio_path TEXT',
      );
    } catch (_) {
      // 列已存在(按最新DDL新建的表已包含)，忽略
    }

    // ===== 会话表 max_tokens/context_message_length 去NOT NULL约束
    // (原v4，2026-09-09对话参数混合方案：null=未设置；temperature/top_p
    // 两列原本就可空无需处理)。SQLite不支持ALTER修改列约束，标准做法：
    // 建新表→拷贝→删旧表→改名
    final newTableDdl = UnifiedChatDdl.ddlForUnifiedConversation.replaceAll(
      UnifiedChatDdl.tableUnifiedConversation,
      '${UnifiedChatDdl.tableUnifiedConversation}_v4_new',
    );

    await db.transaction((txn) async {
      await txn.execute(newTableDdl);
      // 显式列出列名拷贝，不依赖 SELECT * 的列序
      await txn.execute('''
        INSERT INTO ${UnifiedChatDdl.tableUnifiedConversation}_v4_new
        (id, title, model_id, platform_id, partner_id, system_prompt,
         temperature, max_tokens, top_p, frequency_penalty, presence_penalty,
         context_message_length, is_stream, extra_params, message_count,
         total_tokens, total_cost, is_pinned, is_archived,
         current_branch_path, created_at, updated_at)
        SELECT
         id, title, model_id, platform_id, partner_id, system_prompt,
         temperature, max_tokens, top_p, frequency_penalty, presence_penalty,
         context_message_length, is_stream, extra_params, message_count,
         total_tokens, total_cost, is_pinned, is_archived,
         current_branch_path, created_at, updated_at
        FROM ${UnifiedChatDdl.tableUnifiedConversation}
        ''');
      await txn.execute(
        'DROP TABLE ${UnifiedChatDdl.tableUnifiedConversation}',
      );
      await txn.execute(
        'ALTER TABLE ${UnifiedChatDdl.tableUnifiedConversation}_v4_new '
        'RENAME TO ${UnifiedChatDdl.tableUnifiedConversation}',
      );

      // 内置搭档参数默认全空(使用平台默认/上下文不限制)：存量行是
      // 老代码以默认值6插入的，清掉使其回到"未设置"语义
      await txn.execute(
        'UPDATE ${UnifiedChatDdl.tableUnifiedChatPartner} SET '
        'context_message_length = NULL, temperature = NULL, '
        'top_p = NULL, max_tokens = NULL '
        'WHERE is_built_in = 1',
      );
    });

    // ===== 内置平台"小米MiMo"种子(原v5，2026-09-10，对话/语音识别/
    // 语音合成共用chat completions端点；仅replace自身行不影响用户数据)
    await UnifiedChatDdl.initDefaultPlatforms(
      db,
      platformId: UnifiedPlatformId.mimo,
    );

    // ===== 移除embedding/reranker模型类型(原v6，2026-09-10：本应用为
    // 聊天客户端，这两类模型从无调用流程；字符串解析处已有default兜底)
    await db.delete(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: "model_type IN ('embedding', 'reranker')",
    );

    // ===== MCP集成(原v7，2026-09-11)：新增MCP server配置表并补插
    // 内置测试源种子(DeepWiki/Context7/MS Learn，仅补缺不覆盖)。
    // 建表用当前DDL即含全部扩展列，原v8~v11的5条mcp_server ALTER
    // 在合并时间线下全部是重复列操作(合并纰漏，2026-09-18修复)
    await db.execute(UnifiedChatDdl.ddlForUnifiedMcpServer);
    await UnifiedChatDdl.initDefaultMcpServers(db);

    // ===== 多轮工具调用分段列(原v8，2026-09-12)：仅message表的segments；
    // mcp_server表的is_search_source已随上方建表自带
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatMessage} ADD COLUMN segments TEXT',
    );

    // ===== SKILLS P0-1(原v12，2026-09-16)：技能元数据表+搭档挂载列
    await db.execute(UnifiedChatDdl.ddlForUnifiedSkill);
    await db.execute(
      'ALTER TABLE ${UnifiedChatDdl.tableUnifiedChatPartner} ADD COLUMN skill_ids TEXT',
    );

    // ===== 内置平台"OpenRouter"种子(原v13+v14，2026-09-18，两步合并为
    // 最终完整定义：400+模型的OpenAI兼容聚合网关，全模态；仅replace
    // 自身行不影响用户数据)
    await UnifiedChatDdl.initDefaultPlatforms(
      db,
      platformId: UnifiedPlatformId.openrouter,
    );
  }

  /// 把非system消息串成一条单链(每条消息是前一条的子节点)，system消息不入树
  Future<void> _backfillBranchColumns(Database db) async {
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedChatMessage,
      orderBy: 'created_at ASC',
    );

    // 按会话分组
    final byConversation = <String, List<Map<String, dynamic>>>{};
    for (final row in maps) {
      final convId = row['conversation_id'] as String;
      byConversation.putIfAbsent(convId, () => []).add(row);
    }

    final batch = db.batch();
    for (final entry in byConversation.entries) {
      String? lastParentId;
      String lastPath = '';
      int chainDepth = -1;

      for (final row in entry.value) {
        final id = row['id'] as String;
        final role = row['role'] as String;

        // system消息不入树：depth=-1、branch_path=''
        if (role == 'system') {
          batch.update(
            UnifiedChatDdl.tableUnifiedChatMessage,
            {'depth': -1, 'branch_path': ''},
            where: 'id = ?',
            whereArgs: [id],
          );
          continue;
        }

        chainDepth++;
        final path = chainDepth == 0 ? '0' : '$lastPath/0';
        batch.update(
          UnifiedChatDdl.tableUnifiedChatMessage,
          {
            'parent_id': lastParentId,
            'branch_index': 0,
            'depth': chainDepth,
            'branch_path': path,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        lastParentId = id;
        lastPath = path;
      }
    }

    await batch.commit(noResult: true);
  }

  // 对话相关表索引
  Future<void> _createUnifiedChatIndex(Transaction txn) async {
    List<String> indexList = [
      'CREATE INDEX idx_conversations_created_at ON ${UnifiedChatDdl.tableUnifiedConversation} (created_at DESC)',
      'CREATE INDEX idx_conversations_updated_at ON ${UnifiedChatDdl.tableUnifiedConversation} (updated_at DESC)',
      'CREATE INDEX idx_messages_conversation_id ON ${UnifiedChatDdl.tableUnifiedChatMessage} (conversation_id)',
      'CREATE INDEX idx_messages_created_at ON ${UnifiedChatDdl.tableUnifiedChatMessage} (created_at)',
      'CREATE INDEX idx_models_platform_id ON ${UnifiedChatDdl.tableUnifiedModelSpec} (platform_id)',
      'CREATE INDEX idx_messages_parent_id ON ${UnifiedChatDdl.tableUnifiedChatMessage} (conversation_id, parent_id)',
      'CREATE INDEX idx_messages_branch_path ON ${UnifiedChatDdl.tableUnifiedChatMessage} (conversation_id, branch_path)',
    ];

    for (var index in indexList) {
      await txn.execute(index);
    }
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("db.isOpen ${db.isOpen}");
    await db.close();
    print("db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite db文件，db文件地址：$dbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dbFilePath);

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;
  }

  // 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    )).map((row) => row['name'] as String).toList(growable: false);

    print("DB中拥有的表名:------------");
    print(tableNames);
  }

  // 导出所有数据
  // targetDir: 指定导出目录(比如全量备份时直接导出到主库的临时导出目录，一起打进zip包)；
  //   不传时默认导出到本库自己的备份目录
  Future<String> exportDatabase({Directory? targetDir}) async {
    // 2025-10-21 简单点，直接从db这里就导出到指定文件夹（因为创建db时就已经获取存取权限了，这里不重复）
    Directory appDocDir = await getUnifiedChatBackupDir();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(
      p.join(appDocDir.path, DBInitConfig.exportDir),
    ).create();

    // 如果有指定目标目录，则导出到指定目录
    if (targetDir != null) {
      tempDir = await targetDir.create();
    }

    // 打开数据库
    Database db = await database;

    // 获取所有表名
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    // 遍历所有表
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'];
      // 不是自建的表，不导出
      if (!tableName.startsWith(DBInitConfig.tablePerfix)) {
        continue;
      }

      String tempFilePath = p.join(tempDir.path, '$tableName.json');

      // 查询表中所有数据
      List<Map<String, dynamic>> result = await db.query(tableName);

      // 将结果转换为JSON字符串
      String jsonStr = jsonEncode(result);

      // 创建临时导出文件
      File tempFile = File(tempFilePath);

      // 将JSON字符串写入临时文件
      await tempFile.writeAsString(jsonStr);

      // print('表 $tableName 已成功导出到：$tempFilePath');
    }

    return tempDir.path;
  }

  /// 仅供迁移验证测试使用(flutter test, 2026-09-18)：在指定db上按生产
  /// 同款逻辑执行版本升级，验证"0.1.4(v1)库 → 合并迁移 → 当前结构"。
  /// 生产路径走openDatabase的onUpgrade回调进入_upgradeDb，勿用它
  @visibleForTesting
  static Future<void> runUpgradeForVerification(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await UnifiedChatDBInit()._upgradeDb(db, oldVersion, newVersion);
  }
}
