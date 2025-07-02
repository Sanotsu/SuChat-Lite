import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_simple_accounting.dart';
import '../../../core/utils/simple_tools.dart';
import '../domain/entities/bill_item.dart';
import '../domain/entities/bill_category.dart';
import '../domain/entities/bill_statistics.dart';

/// 简单记账仓库实现类
class BillDao {
  // 单例模式
  static final BillDao _dao = BillDao._createInstance();
  // 构造函数，返回单例
  factory BillDao() => _dao;

  // 命名的构造函数用于创建DatabaseHelper的实例
  BillDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  final dbInit = DBInit();

  /// 插入账单条目
  Future<int> insertBillItem(BillItem billItem) async {
    final db = await dbInit.database;
    return await db.insert(
      SimpleAccountingDdl.tableBillItem,
      billItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入账单条目
  Future<List<int>> batchInsertBillItem(List<BillItem> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        SimpleAccountingDdl.tableBillItem,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  /// 更新账单条目
  Future<int> updateBillItem(BillItem billItem) async {
    final db = await dbInit.database;
    return await db.update(
      SimpleAccountingDdl.tableBillItem,
      billItem.toMap(),
      where: 'bill_item_id = ?',
      whereArgs: [billItem.billItemId],
    );
  }

  /// 删除账单条目
  Future<int> deleteBillItem(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      SimpleAccountingDdl.tableBillItem,
      where: 'bill_item_id = ?',
      whereArgs: [id],
    );
  }

  /// 获取账单条目
  Future<BillItem?> getBillItem(int id) async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      where: 'bill_item_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return BillItem.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有账单条目
  Future<List<BillItem>> getAllBillItems() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return BillItem.fromMap(maps[i]);
    });
  }

  /// 按月份获取账单条目
  Future<List<BillItem>> getBillItemsByMonth(
    int year,
    int month, {
    int? itemType,
    String? category,
  }) async {
    final db = await dbInit.database;

    // 构建月份的开始和结束日期
    String startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    String endDate;

    if (month == 12) {
      endDate = '${year + 1}-01-01';
    } else {
      endDate = '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    }

    // 构建WHERE条件
    String whereClause = 'date >= ? AND date < ?';
    List<dynamic> whereArgs = [startDate, endDate];

    // 添加类型过滤
    if (itemType != null) {
      whereClause += ' AND item_type = ?';
      whereArgs.add(itemType);
    }

    // 添加分类过滤
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return BillItem.fromMap(maps[i]);
    });
  }

  /// 按周获取账单条目
  Future<List<BillItem>> getBillItemsByWeek(
    DateTime startDate,
    DateTime endDate, {
    int? itemType,
    String? category,
  }) async {
    final db = await dbInit.database;

    String formattedStartDate =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    String formattedEndDate =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    // 构建WHERE条件
    String whereClause = 'date >= ? AND date <= ?';
    List<dynamic> whereArgs = [formattedStartDate, formattedEndDate];

    // 添加类型过滤
    if (itemType != null) {
      whereClause += ' AND item_type = ?';
      whereArgs.add(itemType);
    }

    // 添加分类过滤
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return BillItem.fromMap(maps[i]);
    });
  }

  /// 按年份获取账单条目
  Future<List<BillItem>> getBillItemsByYear(
    int year, {
    int? itemType,
    String? category,
  }) async {
    final db = await dbInit.database;

    String startDate = '$year-01-01';
    String endDate = '${year + 1}-01-01';

    // 构建WHERE条件
    String whereClause = 'date >= ? AND date < ?';
    List<dynamic> whereArgs = [startDate, endDate];

    // 添加类型过滤
    if (itemType != null) {
      whereClause += ' AND item_type = ?';
      whereArgs.add(itemType);
    }

    // 添加分类过滤
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return BillItem.fromMap(maps[i]);
    });
  }

  /// 获取账单中最大日期
  Future<DateTime> getMaxDate() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      orderBy: 'date DESC, time DESC',
    );
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['date']);
    }
    return DateTime.now();
  }

  /// 获取账单中最小日期
  Future<DateTime> getMinDate() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      orderBy: 'date ASC',
    );
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['date']);
    }
    return DateTime.now();
  }

  /// 搜索账单条目
  Future<List<BillItem>> searchBillItems(String keyword) async {
    final db = await dbInit.database;

    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      where: 'item LIKE ? OR category LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return BillItem.fromMap(maps[i]);
    });
  }

  /// 获取账单统计数据（按月）
  Future<BillStatistics> getMonthlyStatistics(
    int year,
    int month, {
    int? itemType,
    String? category,
  }) async {
    final billItems = await getBillItemsByMonth(
      year,
      month,
      itemType: itemType,
      category: category,
    );
    return _calculateStatistics(billItems);
  }

  /// 获取账单统计数据（按周）
  Future<BillStatistics> getWeeklyStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final billItems = await getBillItemsByWeek(startDate, endDate);
    return _calculateStatistics(billItems);
  }

  /// 获取账单统计数据（按年）
  Future<BillStatistics> getYearlyStatistics(int year) async {
    final billItems = await getBillItemsByYear(year);
    return _calculateStatistics(billItems);
  }

  /// 计算统计数据
  BillStatistics _calculateStatistics(List<BillItem> billItems) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> expenseByCategory = {};
    Map<String, double> incomeByCategory = {};
    Map<String, double> expenseByDate = {};
    Map<String, double> incomeByDate = {};

    for (var item in billItems) {
      if (item.itemType == 0) {
        // 收入
        totalIncome += item.value;

        // 按分类统计
        if (incomeByCategory.containsKey(item.category)) {
          incomeByCategory[item.category] =
              incomeByCategory[item.category]! + item.value;
        } else {
          incomeByCategory[item.category] = item.value;
        }

        // 按日期统计
        if (incomeByDate.containsKey(item.date)) {
          incomeByDate[item.date] = incomeByDate[item.date]! + item.value;
        } else {
          incomeByDate[item.date] = item.value;
        }
      } else {
        // 支出
        totalExpense += item.value;

        // 按分类统计
        if (expenseByCategory.containsKey(item.category)) {
          expenseByCategory[item.category] =
              expenseByCategory[item.category]! + item.value;
        } else {
          expenseByCategory[item.category] = item.value;
        }

        // 按日期统计
        if (expenseByDate.containsKey(item.date)) {
          expenseByDate[item.date] = expenseByDate[item.date]! + item.value;
        } else {
          expenseByDate[item.date] = item.value;
        }
      }
    }

    return BillStatistics(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netIncome: totalIncome - totalExpense,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      expenseByDate: expenseByDate,
      incomeByDate: incomeByDate,
    );
  }

  /// 获取所有账单分类
  Future<List<BillCategory>> getAllCategories() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillCategory,
      orderBy: 'type ASC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return BillCategory.fromMap(maps[i]);
    });
  }

  /// 获取支出分类
  Future<List<BillCategory>> getExpenseCategories() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillCategory,
      where: 'type = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return BillCategory.fromMap(maps[i]);
    });
  }

  /// 获取收入分类
  Future<List<BillCategory>> getIncomeCategories() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillCategory,
      where: 'type = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      return BillCategory.fromMap(maps[i]);
    });
  }

  /// 添加账单分类
  Future<int> addCategory(BillCategory category) async {
    final db = await dbInit.database;
    return await db.insert(
      SimpleAccountingDdl.tableBillCategory,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入账单分类
  Future<List<int>> batchInsertCategory(List<BillCategory> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        SimpleAccountingDdl.tableBillCategory,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  /// 更新账单分类
  Future<int> updateCategory(BillCategory category) async {
    final db = await dbInit.database;
    return await db.update(
      SimpleAccountingDdl.tableBillCategory,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// 删除账单分类
  Future<int> deleteCategory(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      SimpleAccountingDdl.tableBillCategory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 从JSON导入账单数据
  Future<int> importFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<BillItem> billItems =
          jsonList.map((item) => BillItem.fromMap(item)).toList();

      final db = await dbInit.database;
      int count = 0;

      await db.transaction((txn) async {
        for (var item in billItems) {
          await txn.insert(
            SimpleAccountingDdl.tableBillItem,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          count++;
        }
      });

      return count;
    } catch (e) {
      pl.e('导入JSON数据失败: $e');
      return 0;
    }
  }

  /// 导出账单数据为JSON
  Future<String> exportToJson() async {
    final billItems = await getAllBillItems();
    final List<Map<String, dynamic>> jsonList =
        billItems.map((item) => item.toMap()).toList();
    return json.encode(jsonList);
  }

  /// 获取账单条目（按时间范围和筛选条件）
  Future<List<BillItem>> getBillItemsByDateRange(
    String startDate,
    String endDate, {
    int? itemType,
    String? category,
  }) async {
    final db = await dbInit.database;

    // 构建WHERE条件
    String whereClause = 'date >= ? AND date <= ?';
    List<dynamic> whereArgs = [startDate, endDate];

    // 添加类型过滤
    if (itemType != null) {
      whereClause += ' AND item_type = ?';
      whereArgs.add(itemType);
    }

    // 添加分类过滤
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      SimpleAccountingDdl.tableBillItem,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, time DESC',
    );

    return List.generate(maps.length, (i) {
      return BillItem.fromMap(maps[i]);
    });
  }
}
