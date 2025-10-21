// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/storage/db_config.dart';
import '../../../../core/utils/get_dir.dart';
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

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 如果是桌面端（Windows/Linux/macOS），初始化 FFI
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 在任何平台操作之前首先初始化FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi; // 设置全局 databaseFactory
    }

    // 自定义的sqlite数据库文件保存的目录
    Directory directory = await getSqliteDbDir();
    String path = "${directory.path}/${DBInitConfig.chatDbName}";

    print("初始化 Chat DB sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );

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

      // 创建一些索引来提高查询性能
      await _createUnifiedChatIndex(txn);
    });

    /// 初始化默认值
    await UnifiedChatDdl.initDefaultPlatforms(db);
    await UnifiedChatDdl.initDefaultPartners(db);
  }

  // 数据库升级
  void _upgradeDb(Database db, int oldVersion, int newVersion) async {
    print("Chat 数据库升级 _upgradeDb 从 $oldVersion 到 $newVersion");

    if (oldVersion < 2) {}
  }

  // 对话相关表索引
  Future<void> _createUnifiedChatIndex(Transaction txn) async {
    List<String> indexList = [
      'CREATE INDEX idx_conversations_created_at ON ${UnifiedChatDdl.tableUnifiedConversation} (created_at DESC)',
      'CREATE INDEX idx_conversations_updated_at ON ${UnifiedChatDdl.tableUnifiedConversation} (updated_at DESC)',
      'CREATE INDEX idx_messages_conversation_id ON ${UnifiedChatDdl.tableUnifiedChatMessage} (conversation_id)',
      'CREATE INDEX idx_messages_created_at ON ${UnifiedChatDdl.tableUnifiedChatMessage} (created_at)',
      'CREATE INDEX idx_models_platform_id ON ${UnifiedChatDdl.tableUnifiedModelSpec} (platform_id)',
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
  Future<String> exportDatabase() async {
    // 2025-10-21 简单点，直接从db这里就导出到指定文件夹（因为创建db时就已经获取存取权限了，这里不重复）
    Directory appDocDir = await getUnifiedChatBackupDir();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(
      p.join(appDocDir.path, DBInitConfig.exportDir),
    ).create();

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
}
