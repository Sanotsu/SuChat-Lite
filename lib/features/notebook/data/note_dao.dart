import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_notebook.dart';
import '../domain/entities/note.dart';
import '../domain/entities/note_category.dart';
import '../domain/entities/note_media.dart';
import '../domain/entities/note_tag.dart';

/// 笔记仓库实现
class NoteDao {
  // 单例模式
  static final NoteDao _dao = NoteDao._createInstance();
  // 构造函数，返回单例
  factory NoteDao() => _dao;

  // 命名的构造函数用于创建DatabaseHelper的实例
  NoteDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  final dbInit = DBInit();

  // 笔记相关操作
  Future<List<Note>> getNotes({
    String? searchQuery,
    int? categoryId,
    bool? isTodo,
    bool? isCompleted,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final db = await dbInit.database;

    String query = '''
      SELECT n.*, c.name as category_name, c.color as category_color, c.icon as category_icon 
      FROM ${NotebookDdl.tableNote} n
      LEFT JOIN ${NotebookDdl.tableNoteCategory} c ON n.category_id = c.category_id
      WHERE 1=1
    ''';

    List<dynamic> args = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND (n.title LIKE ? OR n.content LIKE ?)';
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    if (categoryId != null) {
      query += ' AND n.category_id = ?';
      args.add(categoryId);
    }

    if (isTodo != null) {
      query += ' AND n.is_todo = ?';
      args.add(isTodo ? 1 : 0);
    }

    if (isCompleted != null) {
      query += ' AND n.is_completed = ?';
      args.add(isCompleted ? 1 : 0);
    }

    if (isPinned != null) {
      query += ' AND n.is_pinned = ?';
      args.add(isPinned ? 1 : 0);
    }

    if (isArchived != null) {
      query += ' AND n.is_archived = ?';
      args.add(isArchived ? 1 : 0);
    }

    // 排序：先置顶，再按更新时间倒序
    query += ' ORDER BY n.is_pinned DESC, n.updated_at DESC';

    final noteRows = await db.rawQuery(query, args);

    // 转换为Note对象
    final notes = <Note>[];
    for (final row in noteRows) {
      final note = Note.fromMap(row);

      // 添加分类信息
      if (row['category_id'] != null) {
        note.category = NoteCategory(
          id: row['category_id'] as int,
          name: row['category_name'] as String,
          color: int.tryParse(row['category_color'].toString()),
          icon: row['category_icon'] as String?,
        );
      }

      // 获取笔记的标签
      note.tags = await getTagsForNote(note.id!);

      // 获取笔记的媒体附件
      note.mediaList = await getMediaForNote(note.id!);

      notes.add(note);
    }

    return notes;
  }

  Future<Note?> getNoteById(int id) async {
    final db = await dbInit.database;

    final noteRows = await db.rawQuery(
      '''
      SELECT n.*, c.name as category_name, c.color as category_color, c.icon as category_icon 
      FROM ${NotebookDdl.tableNote} n
      LEFT JOIN ${NotebookDdl.tableNoteCategory} c ON n.category_id = c.category_id
      WHERE n.note_id = ?
    ''',
      [id],
    );

    if (noteRows.isEmpty) {
      return null;
    }

    final row = noteRows.first;
    final note = Note.fromMap(row);

    // 添加分类信息
    if (row['category_id'] != null) {
      note.category = NoteCategory(
        id: row['category_id'] as int,
        name: row['category_name'] as String,
        color: int.tryParse(row['category_color'].toString()),
        icon: row['category_icon'] as String?,
      );
    }

    // 获取笔记的标签
    note.tags = await getTagsForNote(note.id!);

    // 获取笔记的媒体附件
    note.mediaList = await getMediaForNote(note.id!);

    return note;
  }

  Future<Note> createNote(Note note) async {
    final db = await dbInit.database;

    // 更新时间戳
    note.createdAt = DateTime.now();
    note.updatedAt = DateTime.now();

    // 插入笔记
    final noteId = await db.insert(
      NotebookDdl.tableNote,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 更新笔记ID
    note.id = noteId;

    // 保存标签关联
    for (final tag in note.tags) {
      if (tag.id != null) {
        await addTagToNote(noteId, tag.id!);
      }
    }

    // 保存媒体附件
    for (final media in note.mediaList) {
      final mediaWithNoteId = media.copyWith(noteId: noteId);
      await addMediaToNote(mediaWithNoteId);
    }

    return note;
  }

  Future<List<Note>> batchCreateNote(List<Note> items) async {
    final List<Note> createdNotes = [];

    for (final item in items) {
      final createdNote = await createNote(item);
      createdNotes.add(createdNote);
    }

    return createdNotes;
  }

  Future<Note> updateNote(Note note) async {
    final db = await dbInit.database;

    // 更新时间戳
    note.updatedAt = DateTime.now();

    // 更新笔记
    await db.update(
      NotebookDdl.tableNote,
      note.toMap(),
      where: 'note_id = ?',
      whereArgs: [note.id],
    );

    // 更新标签关联
    // 首先删除所有关联
    await db.delete(
      NotebookDdl.tableNoteTagRelation,
      where: 'note_id = ?',
      whereArgs: [note.id],
    );

    // 重新添加关联
    for (final tag in note.tags) {
      if (tag.id != null) {
        await addTagToNote(note.id!, tag.id!);
      }
    }

    return note;
  }

  Future<void> deleteNote(int id) async {
    final db = await dbInit.database;

    // 删除笔记（关联的标签关系和媒体会通过外键级联删除）
    await db.delete(
      NotebookDdl.tableNote,
      where: 'note_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> getTodoNotes({bool? isCompleted}) async {
    return getNotes(
      isTodo: true,
      isCompleted: isCompleted,
      isArchived: false, // 不显示已归档的待办事项
    );
  }

  // 分类相关操作

  Future<List<NoteCategory>> getCategories() async {
    final db = await dbInit.database;

    final rows = await db.query(
      NotebookDdl.tableNoteCategory,
      orderBy: 'sort_order ASC',
    );

    return rows.map((row) => NoteCategory.fromMap(row)).toList();
  }

  Future<NoteCategory?> getCategoryById(int id) async {
    final db = await dbInit.database;

    final rows = await db.query(
      NotebookDdl.tableNoteCategory,
      where: 'category_id = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return NoteCategory.fromMap(rows.first);
  }

  Future<NoteCategory> createCategory(NoteCategory category) async {
    final db = await dbInit.database;

    final id = await db.insert(
      NotebookDdl.tableNoteCategory,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return category.copyWith(id: id);
  }

  Future<List<int>> batchCreateCategory(List<NoteCategory> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        NotebookDdl.tableNoteCategory,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<NoteCategory> updateCategory(NoteCategory category) async {
    final db = await dbInit.database;

    await db.update(
      NotebookDdl.tableNoteCategory,
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.id],
    );

    return category;
  }

  Future<void> deleteCategory(int id) async {
    final db = await dbInit.database;

    // 删除分类（笔记中的分类ID会设置为null）
    await db.delete(
      NotebookDdl.tableNoteCategory,
      where: 'category_id = ?',
      whereArgs: [id],
    );
  }

  // 标签相关操作

  Future<List<NoteTag>> getTags() async {
    final db = await dbInit.database;

    final rows = await db.query(NotebookDdl.tableNoteTag, orderBy: 'name ASC');

    return rows.map((row) => NoteTag.fromMap(row)).toList();
  }

  Future<List<NoteTag>> getTagsForNote(int noteId) async {
    final db = await dbInit.database;

    final rows = await db.rawQuery(
      '''
      SELECT t.* FROM ${NotebookDdl.tableNoteTag} t
      JOIN ${NotebookDdl.tableNoteTagRelation} r ON t.tag_id = r.tag_id
      WHERE r.note_id = ?
      ORDER BY t.name ASC
    ''',
      [noteId],
    );

    return rows.map((row) => NoteTag.fromMap(row)).toList();
  }

  Future<NoteTag?> getTagById(int id) async {
    final db = await dbInit.database;

    final rows = await db.query(
      NotebookDdl.tableNoteTag,
      where: 'tag_id = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return NoteTag.fromMap(rows.first);
  }

  Future<NoteTag> createTag(NoteTag tag) async {
    final db = await dbInit.database;

    final id = await db.insert(
      NotebookDdl.tableNoteTag,
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return tag.copyWith(id: id);
  }

  Future<List<int>> batchCreateTag(List<NoteTag> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        NotebookDdl.tableNoteTag,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<NoteTag> updateTag(NoteTag tag) async {
    final db = await dbInit.database;

    await db.update(
      NotebookDdl.tableNoteTag,
      tag.toMap(),
      where: 'tag_id = ?',
      whereArgs: [tag.id],
    );

    return tag;
  }

  Future<void> deleteTag(int id) async {
    final db = await dbInit.database;

    // 删除标签（关联关系会通过外键级联删除）
    await db.delete(
      NotebookDdl.tableNoteTag,
      where: 'tag_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addTagToNote(int noteId, int tagId) async {
    final db = await dbInit.database;

    await db.insert(
      NotebookDdl.tableNoteTagRelation,
      {'note_id': noteId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 备份恢复时用到
  Future<List<int>> batchCreateNoteTagRelation(List<dynamic> jsons) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in jsons) {
      if (item['note_id'] == null || item['tag_id'] == null) {
        continue;
      }

      batch.insert(
        NotebookDdl.tableNoteTagRelation,
        {'note_id': item['note_id'], 'tag_id': item['tag_id']},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<void> removeTagFromNote(int noteId, int tagId) async {
    final db = await dbInit.database;

    await db.delete(
      NotebookDdl.tableNoteTagRelation,
      where: 'note_id = ? AND tag_id = ?',
      whereArgs: [noteId, tagId],
    );
  }

  // 媒体相关操作

  Future<List<NoteMedia>> getMediaForNote(int noteId) async {
    final db = await dbInit.database;

    final rows = await db.query(
      NotebookDdl.tableNoteMedia,
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );

    return rows.map((row) => NoteMedia.fromMap(row)).toList();
  }

  Future<NoteMedia> addMediaToNote(NoteMedia media) async {
    final db = await dbInit.database;

    final id = await db.insert(
      NotebookDdl.tableNoteMedia,
      media.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return media.copyWith(id: id);
  }

  Future<List<int>> batchCreateMedia(List<NoteMedia> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        NotebookDdl.tableNoteMedia,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<void> deleteMedia(int id) async {
    final db = await dbInit.database;

    await db.delete(
      NotebookDdl.tableNoteMedia,
      where: 'media_id = ?',
      whereArgs: [id],
    );
  }
}
