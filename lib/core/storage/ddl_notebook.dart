import 'package:sqflite/sqflite.dart';

import 'db_config.dart';

/// 记事本模块的数据库表定义
class NotebookDdl {
  /// 笔记表
  static const String tableNote = '${DBInitConfig.tablePerfix}note';

  static const ddlForNote = """
    CREATE TABLE IF NOT EXISTS $tableNote (
      note_id             INTEGER   PRIMARY KEY AUTOINCREMENT,
      title               TEXT      NOT NULL,
      content             TEXT      NOT NULL,
      content_delta       TEXT      NOT NULL,            /* 存储富文本Delta格式 */
      category_id         INTEGER,
      is_todo             INTEGER   NOT NULL DEFAULT 0,  /* 是否为待办事项 */
      is_completed        INTEGER   NOT NULL DEFAULT 0,  /* 待办事项是否已完成 */
      created_at          TEXT      NOT NULL,
      updated_at          TEXT      NOT NULL,
      color               INTEGER,                       /* 笔记颜色 , color.ARGB32()*/
      is_pinned           INTEGER   NOT NULL DEFAULT 0,  /* 是否置顶 */
      is_archived         INTEGER   NOT NULL DEFAULT 0,  /* 是否归档 */
      reminder_time       TEXT,                          /* 提醒时间 */
      FOREIGN KEY (category_id) REFERENCES $tableNoteCategory (category_id) ON DELETE SET NULL
    )
    """;

  /// 笔记分类表
  static const String tableNoteCategory =
      '${DBInitConfig.tablePerfix}note_category';

  static const ddlForNoteCategory = """
    CREATE TABLE IF NOT EXISTS $tableNoteCategory (
      category_id         INTEGER   PRIMARY KEY AUTOINCREMENT,
      name                TEXT      NOT NULL,
      color               INTEGER,                        /* 分类颜色 , color.ARGB32()*/
      icon                TEXT,
      sort_order          INTEGER   NOT NULL DEFAULT 0
    )
    """;

  /// 笔记标签表
  static const String tableNoteTag = '${DBInitConfig.tablePerfix}note_tag';

  static const ddlForNoteTag = """
    CREATE TABLE IF NOT EXISTS $tableNoteTag (
      tag_id              INTEGER   PRIMARY KEY AUTOINCREMENT,
      name                TEXT      NOT NULL UNIQUE,
      color               INTEGER                         /* 标签颜色 , color.ARGB32()*/
    )
    """;

  /// 笔记-标签关联表
  static const String tableNoteTagRelation =
      '${DBInitConfig.tablePerfix}note_tag_relation';

  static const ddlForNoteTagRelation = """
    CREATE TABLE IF NOT EXISTS $tableNoteTagRelation (
      note_id             INTEGER   NOT NULL,
      tag_id              INTEGER   NOT NULL,
      PRIMARY KEY (note_id, tag_id),
      FOREIGN KEY (note_id) REFERENCES $tableNote (note_id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id) REFERENCES $tableNoteTag (tag_id) ON DELETE CASCADE
    )
    """;

  /// 笔记媒体附件表
  static const String tableNoteMedia = '${DBInitConfig.tablePerfix}note_media';

  static const ddlForNoteMedia = """
    CREATE TABLE IF NOT EXISTS $tableNoteMedia (
      media_id            INTEGER   PRIMARY KEY AUTOINCREMENT,
      note_id             INTEGER   NOT NULL,
      media_type          TEXT      NOT NULL,
      media_path          TEXT      NOT NULL,
      thumbnail_path      TEXT,
      created_at          TEXT      NOT NULL,
      FOREIGN KEY (note_id) REFERENCES $tableNote (note_id) ON DELETE CASCADE
    )
    """;

  /// 初始化默认笔记分类数据
  static Future<void> initDefaultCategories(Database db) async {
    // 检查是否已经有分类数据
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableNoteCategory'),
    );

    if (count == 0) {
      final batch = db.batch();
      final List<Map<String, dynamic>> noteCategories = [
        // 绿色
        {'name': '个人', 'color': 0xFF4CAF50, 'icon': 'person', 'sort_order': 0},
        // 蓝色
        {'name': '工作', 'color': 0xFF2196F3, 'icon': 'work', 'sort_order': 1},
        // 橙色
        {'name': '学习', 'color': 0xFFFF9800, 'icon': 'school', 'sort_order': 2},
        // 紫色
        {
          'name': '灵感',
          'color': 0xFF9C27B0,
          'icon': 'lightbulb',
          'sort_order': 3,
        },
        // 黄色
        {'name': '旅行', 'color': 0xFFFFC107, 'icon': 'flight', 'sort_order': 4},
        // 粉红色
        {
          'name': '购物',
          'color': 0xFFE91E63,
          'icon': 'shopping_cart',
          'sort_order': 5,
        },
      ];

      for (var item in noteCategories) {
        batch.insert(tableNoteCategory, {
          'name': item['name'],
          'color': item['color'],
          'icon': item['icon'],
          'sort_order': item['sort_order'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit();
    }
  }
}
