// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/get_dir.dart';
import 'db_config.dart';
import 'db_ddl.dart';
import 'ddl_diet_diary.dart';
import 'ddl_notebook.dart';
import 'ddl_simple_accounting.dart';
import 'ddl_training.dart';

class DBInit {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBInit _dbInit = DBInit._createInstance();
  // 构造函数，返回单例
  factory DBInit() => _dbInit;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBInit._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 如果是桌面端（Windows/Linux/macOS），初始化 FFI
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 在任何平台操作之前首先初始化FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi; // 设置全局 databaseFactory

      // 首先确保linux环境有安装，不然这个initializeDB应该会报错
      // sudo apt-get -y install libsqlite3-0 libsqlite3-dev

      // 针对Linux平台的特殊处理，这个不启用也应该正常
      // if (Platform.isLinux) {
      //   try {
      //     // 尝试使用自定义库路径
      //     var options = OpenDatabaseOptions(readOnly: true);
      //     // 可以尝试不同路径的SQLite库文件
      //     final List<String> possiblePaths = [
      //       'libsqlite3.so',
      //       '/usr/lib/x86_64-linux-gnu/libsqlite3.so',
      //       '/usr/lib/libsqlite3.so',
      //     ];

      //     // 尝试所有可能的库路径
      //     for (var path in possiblePaths) {
      //       try {
      //         print("尝试加载SQLite库: $path");
      //         await databaseFactoryFfi.openDatabase(
      //           ":memory:",
      //           options: options,
      //         );
      //         break; // 如果成功，跳出循环
      //       } catch (e) {
      //         print("无法加载 $path: $e");
      //         // 继续尝试下一个路径
      //       }
      //     }
      //   } catch (e) {
      //     print("初始化SQLite FFI时出错: $e");
      //   }
      // }
    }

    // 自定义的sqlite数据库文件保存的目录
    Directory directory = await getSqliteDbDir();
    String path = "${directory.path}/${DBInitConfig.databaseName}";

    print("初始化 DB sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var db = await openDatabase(
      path,
      version: 2, // 更新数据库版本号
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
      txn.execute(DBDdl.ddlForMediaGenerationHistory);
      txn.execute(DBDdl.ddlForCusLlmSpec);
      txn.execute(DBDdl.ddlForVoiceRecognitionTask);

      // 创建统一用户表
      txn.execute(DBDdl.ddlForUserInfo);
      // 创建用户表索引
      await _createUserInfoIndex(txn);

      // 添加训练助手相关表
      await _createTrainingTable(txn);

      // 添加饮食日记相关表
      await _createDietDiaryTable(txn);
      // 创建一些索引来提高查询性能
      await _createDietDiaryIndex(txn);

      // 添加简单记账相关表
      await _createSimpleAccountingTable(txn);

      // 添加记事本相关表
      await _createNotebookTable(txn);
      // 创建记事本相关索引
      await _createNotebookIndex(txn);
    });

    /// 初始化默认值

    // 初始化默认账单分类数据
    await SimpleAccountingDdl.initDefaultCategories(db);

    // 初始化默认笔记分类数据
    await NotebookDdl.initDefaultCategories(db);
  }

  // 数据库升级
  void _upgradeDb(Database db, int oldVersion, int newVersion) async {
    print("数据库升级 _upgradeDb 从 $oldVersion 到 $newVersion");

    if (oldVersion < 2) {
      await db.transaction((txn) async {
        // 创建新的统一用户表
        txn.execute(DBDdl.ddlForUserInfo);
        // 创建用户表索引
        await _createUserInfoIndex(txn);

        // 添加训练助手相关表
        await _createTrainingTable(txn);

        // 添加饮食日记相关表
        await _createDietDiaryTable(txn);
        // 创建一些索引来提高查询性能
        await _createDietDiaryIndex(txn);

        // 添加简单记账相关表
        await _createSimpleAccountingTable(txn);

        // 添加记事本相关表
        await _createNotebookTable(txn);
        // 创建记事本相关索引
        await _createNotebookIndex(txn);
      });

      // 初始化默认账单分类数据
      await SimpleAccountingDdl.initDefaultCategories(db);

      // 初始化默认笔记分类数据
      await NotebookDdl.initDefaultCategories(db);
    }
  }

  /// 数据库升级和默认都要创建的表
  // 训练助手相关表
  Future<void> _createTrainingTable(Transaction txn) async {
    await txn.execute(TrainingDdl.ddlForTrainingPlan);
    await txn.execute(TrainingDdl.ddlForTrainingPlanDetail);
    await txn.execute(TrainingDdl.ddlForTrainingRecord);
    await txn.execute(TrainingDdl.ddlForTrainingRecordDetail);
  }

  // 饮食日记相关表
  Future<void> _createDietDiaryTable(Transaction txn) async {
    await txn.execute(DietDiaryDdl.ddlForFoodItem);
    await txn.execute(DietDiaryDdl.ddlForMealRecord);
    await txn.execute(DietDiaryDdl.ddlForMealFoodRecord);
    await txn.execute(DietDiaryDdl.ddlForWeightRecord);
    await txn.execute(DietDiaryDdl.ddlForDietAnalysis);
    await txn.execute(DietDiaryDdl.ddlForDietRecipe);
  }

  // 简单记账相关表
  Future<void> _createSimpleAccountingTable(Transaction txn) async {
    await txn.execute(SimpleAccountingDdl.ddlForBillItem);
    await txn.execute(SimpleAccountingDdl.ddlForBillCategory);
  }

  // 记事本相关表
  Future<void> _createNotebookTable(Transaction txn) async {
    await txn.execute(NotebookDdl.ddlForNoteCategory);
    await txn.execute(NotebookDdl.ddlForNote);
    await txn.execute(NotebookDdl.ddlForNoteTag);
    await txn.execute(NotebookDdl.ddlForNoteTagRelation);
    await txn.execute(NotebookDdl.ddlForNoteMedia);
  }

  // 饮食日记相关表索引
  Future<void> _createDietDiaryIndex(Transaction txn) async {
    List<String> indexList = [
      'CREATE INDEX idx_meal_record_date ON ${DietDiaryDdl.tableMealRecord} (date)',
      'CREATE INDEX idx_meal_food_records_meal_id ON ${DietDiaryDdl.tableMealFoodRecord} (mealRecordId)',
      'CREATE INDEX idx_meal_food_records_food_id ON ${DietDiaryDdl.tableMealFoodRecord}  (foodItemId)',
      'CREATE INDEX idx_food_items_name ON ${DietDiaryDdl.tableFoodItem}  (name)',
      'CREATE INDEX idx_food_items_foodcode ON ${DietDiaryDdl.tableFoodItem}  (foodCode)',
      'CREATE INDEX idx_weight_records_date ON ${DietDiaryDdl.tableWeightRecord}  (date)',
      'CREATE INDEX idx_weight_records_user_id ON ${DietDiaryDdl.tableWeightRecord}  (userId)',
      'CREATE INDEX idx_diet_analysis_date ON ${DietDiaryDdl.tableDietAnalysis} (date)',
      'CREATE INDEX idx_diet_recipe_date ON ${DietDiaryDdl.tableDietRecipe} (date)',
      'CREATE INDEX idx_diet_recipe_analysis_id ON ${DietDiaryDdl.tableDietRecipe} (analysisId)',
    ];

    for (var index in indexList) {
      await txn.execute(index);
    }
  }

  // 记事本相关表索引
  Future<void> _createNotebookIndex(Transaction txn) async {
    List<String> indexList = [
      'CREATE INDEX idx_note_title ON ${NotebookDdl.tableNote} (title)',
      'CREATE INDEX idx_note_category_id ON ${NotebookDdl.tableNote} (category_id)',
      'CREATE INDEX idx_note_created_at ON ${NotebookDdl.tableNote} (created_at)',
      'CREATE INDEX idx_note_updated_at ON ${NotebookDdl.tableNote} (updated_at)',
      'CREATE INDEX idx_note_is_todo ON ${NotebookDdl.tableNote} (is_todo)',
      'CREATE INDEX idx_note_is_completed ON ${NotebookDdl.tableNote} (is_completed)',
      'CREATE INDEX idx_note_is_pinned ON ${NotebookDdl.tableNote} (is_pinned)',
      'CREATE INDEX idx_note_is_archived ON ${NotebookDdl.tableNote} (is_archived)',
      'CREATE INDEX idx_note_media_note_id ON ${NotebookDdl.tableNoteMedia} (note_id)',
      'CREATE INDEX idx_note_media_type ON ${NotebookDdl.tableNoteMedia} (media_type)',
    ];

    for (var index in indexList) {
      await txn.execute(index);
    }
  }

  // 用户表索引
  Future<void> _createUserInfoIndex(Transaction txn) async {
    await txn.execute(
      'CREATE INDEX idx_user_info_user_id ON ${DBDdl.tableUserInfo} (userId)',
    );
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
  Future<void> exportDatabase() async {
    // 获取应用文档目录路径
    // 这个获取缓存目录即可
    Directory appDocDir = await getApplicationCacheDirectory();
    // 创建或检索 db_export 文件夹
    var tempDir =
        await Directory(
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
  }
}
