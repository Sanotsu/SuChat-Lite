import 'package:sqflite/sqflite.dart';

import 'db_config.dart';

/// 极简记账模块的数据库表定义
class SimpleAccountingDdl {
  /// 账单条目表
  static const String tableBillItem = '${DBInitConfig.tablePerfix}bill_item';

  static const ddlForBillItem = """
    CREATE TABLE IF NOT EXISTS $tableBillItem (
      bill_item_id        INTEGER   PRIMARY KEY AUTOINCREMENT,
      category            TEXT      NOT NULL,
      date                TEXT      NOT NULL,
      time                TEXT,
      gmt_modified        TEXT      NOT NULL,
      item                TEXT      NOT NULL,
      item_type           INTEGER   NOT NULL,
      value               REAL      NOT NULL,
      remark              TEXT
      )
    """;

  /// 账单分类表
  static const String tableBillCategory =
      '${DBInitConfig.tablePerfix}bill_category';

  // 2025-06-30 icon好像没办法直接匹配到Icons的枚举值，这里设置了也没用
  // 同理，颜色也没什么实际作用
  static const ddlForBillCategory = """
    CREATE TABLE IF NOT EXISTS $tableBillCategory (
      id                  INTEGER     PRIMARY KEY AUTOINCREMENT,
      name                TEXT        NOT NULL,
      icon                TEXT,
      color               TEXT,
      type                INTEGER     NOT NULL,
      is_default          INTEGER     NOT NULL DEFAULT 0
    )
    """;

  /// 初始化默认账单分类数据
  static Future<void> initDefaultCategories(Database db) async {
    // 检查是否已经有分类数据
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableBillCategory'),
    );

    if (count == 0) {
      final batch = db.batch();
      final List<Map<String, dynamic>> billCategories = [
        // ========== 支出 ==========
        {'name': '餐饮', 'color': '#FF5722', 'type': 1, 'is_default': 1}, // 橙色
        {'name': '交通', 'color': '#2196F3', 'type': 1, 'is_default': 1}, // 蓝色
        {'name': '购物', 'color': '#FF9800', 'type': 1, 'is_default': 1}, // 琥珀色
        {'name': '服饰', 'color': '#E91E63', 'type': 1, 'is_default': 1}, // 粉红色
        {'name': '日用', 'color': '#9C27B0', 'type': 1, 'is_default': 1}, // 紫色
        {'name': '住宿', 'color': '#673AB7', 'type': 1, 'is_default': 1}, // 深紫色
        {'name': '娱乐', 'color': '#00BCD4', 'type': 1, 'is_default': 1}, // 青色
        {'name': '缴费', 'color': '#607D8B', 'type': 1, 'is_default': 1}, // 蓝灰色
        {'name': '数码', 'color': '#3F51B5', 'type': 1, 'is_default': 1}, // 靛蓝色
        {'name': '运动', 'color': '#4CAF50', 'type': 1, 'is_default': 1}, // 绿色
        {'name': '旅行', 'color': '#FFC107', 'type': 1, 'is_default': 1}, // 黄色
        {'name': '宠物', 'color': '#795548', 'type': 1, 'is_default': 1}, // 棕色
        {'name': '教育', 'color': '#009688', 'type': 1, 'is_default': 1}, // 蓝绿色
        {'name': '医疗', 'color': '#F44336', 'type': 1, 'is_default': 1}, // 红色
        {'name': '红包', 'color': '#E53935', 'type': 1, 'is_default': 1}, // 深红色
        {'name': '转账', 'color': '#D81B60', 'type': 1, 'is_default': 1}, // 玫红色
        {'name': '人情', 'color': '#8E24AA', 'type': 1, 'is_default': 1}, // 紫红色
        {'name': '轻奢', 'color': '#FF7043', 'type': 1, 'is_default': 1}, // 浅橙色
        {'name': '美容', 'color': '#EC407A', 'type': 1, 'is_default': 1}, // 亮粉色
        {'name': '亲子', 'color': '#AB47BC', 'type': 1, 'is_default': 1}, // 浅紫色
        {'name': '保险', 'color': '#7E57C2', 'type': 1, 'is_default': 1}, // 中紫色
        {'name': '公益', 'color': '#26A69A', 'type': 1, 'is_default': 1}, // 深蓝绿色
        {'name': '服务', 'color': '#5C6BC0', 'type': 1, 'is_default': 1}, // 中靛蓝
        {'name': '其他', 'color': '#9E9E9E', 'type': 1, 'is_default': 1}, // 灰色
        // ========== 收入 ==========
        {'name': '工资', 'color': '#4CAF50', 'type': 0, 'is_default': 1}, // 绿色
        {'name': '奖金', 'color': '#FFC107', 'type': 0, 'is_default': 1}, // 黄色
        {'name': '生意', 'color': '#2196F3', 'type': 0, 'is_default': 1}, // 蓝色
        {'name': '兼职', 'color': '#00ACC1', 'type': 0, 'is_default': 1}, // 浅蓝色
        {'name': '红包', 'color': '#FF7043', 'type': 0, 'is_default': 1}, // 橙色
        {'name': '转账', 'color': '#7E57C2', 'type': 0, 'is_default': 1}, // 紫色
        {'name': '投资', 'color': '#26C6DA', 'type': 0, 'is_default': 1}, // 亮青色
        {'name': '炒股', 'color': '#42A5F5', 'type': 0, 'is_default': 1}, // 亮蓝色
        {'name': '基金', 'color': '#66BB6A', 'type': 0, 'is_default': 1}, // 浅绿色
        {'name': '人情', 'color': '#FFA726', 'type': 0, 'is_default': 1}, // 深黄色
        {'name': '退款', 'color': '#78909C', 'type': 0, 'is_default': 1}, // 灰蓝色
        {'name': '其他', 'color': '#BDBDBD', 'type': 0, 'is_default': 1}, // 浅灰色
      ];

      for (var item in billCategories) {
        batch.insert(tableBillCategory, {
          'name': item['name'],
          'color': item['color'],
          'type': item['type'],
          'is_default': item['is_default'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit();
    }
  }
}
