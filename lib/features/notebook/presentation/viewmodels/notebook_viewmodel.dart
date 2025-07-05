import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/note_dao.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_category.dart';
import '../../domain/entities/note_media.dart';
import '../../domain/entities/note_tag.dart';

part 'notebook_viewmodel.g.dart';

enum NoteViewType { list, grid }

enum NoteFilterType { all, todo, archived }

@riverpod
class NotebookViewModel extends _$NotebookViewModel {
  late NoteDao _noteRepository;

  @override
  FutureOr<List<Note>> build() async {
    // 初始化仓库
    _noteRepository = NoteDao();

    // 加载笔记列表
    return _loadNotes();
  }

  // 加载笔记列表
  Future<List<Note>> _loadNotes({
    String? searchQuery,
    int? categoryId,
    bool? isTodo,
    bool? isCompleted,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      return await _noteRepository.getNotes(
        searchQuery: searchQuery,
        categoryId: categoryId,
        isTodo: isTodo,
        isCompleted: isCompleted,
        isPinned: isPinned,
        isArchived: isArchived,
      );
    } catch (e) {
      throw Exception('加载笔记失败: $e');
    }
  }

  // 刷新笔记列表
  Future<void> refreshNotes({
    String? searchQuery,
    int? categoryId,
    bool? isTodo,
    bool? isCompleted,
    bool? isPinned,
    bool? isArchived,
  }) async {
    state = const AsyncLoading();
    try {
      final notes = await _loadNotes(
        searchQuery: searchQuery,
        categoryId: categoryId,
        isTodo: isTodo,
        isCompleted: isCompleted,
        isPinned: isPinned,
        isArchived: isArchived,
      );
      state = AsyncValue.data(notes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 获取笔记详情
  Future<Note?> getNoteById(int id) async {
    try {
      return await _noteRepository.getNoteById(id);
    } catch (e) {
      throw Exception('获取笔记详情失败: $e');
    }
  }

  // 创建笔记
  Future<Note> createNote({
    required String title,
    required String content,
    required String contentDelta,
    int? categoryId,
    bool isTodo = false,
    int? color,
    bool isPinned = false,
    List<NoteTag>? tags,
    List<NoteMedia>? mediaList,
  }) async {
    try {
      final note = Note(
        title: title,
        content: content,
        contentDelta: contentDelta,
        categoryId: categoryId,
        isTodo: isTodo,
        color: color,
        isPinned: isPinned,
        tags: tags ?? [],
        mediaList: mediaList ?? [],
      );

      final createdNote = await _noteRepository.createNote(note);

      // 更新状态
      state = AsyncValue.data([...state.value ?? [], createdNote]);

      return createdNote;
    } catch (e) {
      throw Exception('创建笔记失败: $e');
    }
  }

  // 更新笔记
  Future<Note> updateNote(Note note) async {
    try {
      final updatedNote = await _noteRepository.updateNote(note);

      // 更新状态
      if (state.hasValue) {
        final notes = [...state.value!];
        final index = notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          notes[index] = updatedNote;
          state = AsyncValue.data(notes);
        }
      }

      return updatedNote;
    } catch (e) {
      throw Exception('更新笔记失败: $e');
    }
  }

  // 删除笔记
  Future<void> deleteNote(int id) async {
    try {
      await _noteRepository.deleteNote(id);

      // 更新状态
      if (state.hasValue) {
        final notes = state.value!.where((note) => note.id != id).toList();
        state = AsyncValue.data(notes);
      }
    } catch (e) {
      throw Exception('删除笔记失败: $e');
    }
  }

  // 切换待办事项完成状态
  Future<Note> toggleTodoCompleted(Note note) async {
    final updatedNote = note.copyWith(isCompleted: !note.isCompleted);
    return updateNote(updatedNote);
  }

  // 切换笔记置顶状态
  Future<Note> toggleNotePinned(Note note) async {
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    return updateNote(updatedNote);
  }

  // 归档笔记
  Future<Note> archiveNote(Note note) async {
    final updatedNote = note.copyWith(isArchived: true);
    return updateNote(updatedNote);
  }

  // 取消归档笔记
  Future<Note> unarchiveNote(Note note) async {
    final updatedNote = note.copyWith(isArchived: false);
    return updateNote(updatedNote);
  }

  // 保存富文本内容到笔记
  Future<Note> saveQuillContentToNote(
    Note note,
    QuillController quillController,
  ) async {
    // 获取纯文本内容
    final plainText = quillController.document.toPlainText().trim();

    // 获取Delta JSON
    final deltaJson = quillController.document.toDelta().toJson();
    final contentDelta = jsonEncode(deltaJson);

    // 更新笔记
    final updatedNote = note.copyWith(
      content: plainText,
      contentDelta: contentDelta,
      updatedAt: DateTime.now(),
    );

    return updateNote(updatedNote);
  }

  // 从Delta JSON创建QuillController
  QuillController getQuillControllerFromNote(Note note) {
    try {
      if (note.contentDelta.isNotEmpty) {
        // 将字符串转换为JSON对象
        final dynamic deltaJson = jsonDecode(note.contentDelta);
        final document = Document.fromJson(deltaJson);
        return QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      debugPrint('解析笔记Delta内容失败: $e');
    }

    // 如果解析失败或内容为空，创建一个新的控制器
    return QuillController.basic();
  }

  // 添加媒体到笔记
  Future<NoteMedia> addMediaToNote(
    Note note,
    File file,
    String mediaType,
  ) async {
    try {
      // 创建媒体存储目录
      // final appDir = await getApplicationDocumentsDirectory();
      // final mediaDir = Directory('${appDir.path}/note_media');
      // if (!await mediaDir.exists()) {
      //   await mediaDir.create(recursive: true);
      // }

      // // 生成唯一文件名
      // final fileName =
      //     '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      // final mediaPath = '${mediaDir.path}/$fileName';

      // // 复制文件到应用目录
      // await file.copy(mediaPath);

      // 创建媒体对象(录制的时候已经放在了指定位置，这里不需要再处理了)
      final media = NoteMedia(
        noteId: note.id!,
        mediaType: mediaType,
        // mediaPath: mediaPath,
        mediaPath: file.path,
      );

      // 保存到数据库
      final savedMedia = await _noteRepository.addMediaToNote(media);

      // 更新笔记的媒体列表
      note.mediaList.add(savedMedia);

      // 更新状态
      if (state.hasValue) {
        final notes = [...state.value!];
        final index = notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          notes[index] = note;
          state = AsyncValue.data(notes);
        }
      }

      return savedMedia;
    } catch (e) {
      throw Exception('添加媒体到笔记失败: $e');
    }
  }

  // 删除笔记媒体
  Future<void> deleteNoteMedia(Note note, int mediaId) async {
    try {
      // 从数据库删除
      await _noteRepository.deleteMedia(mediaId);

      // 更新笔记的媒体列表
      note.mediaList.removeWhere((media) => media.id == mediaId);

      // 更新状态
      if (state.hasValue) {
        final notes = [...state.value!];
        final index = notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          notes[index] = note;
          state = AsyncValue.data(notes);
        }
      }
    } catch (e) {
      throw Exception('删除笔记媒体失败: $e');
    }
  }

  // 批量归档笔记
  Future<List<Note>> batchArchiveNotes(List<Note> notes) async {
    final List<Note> archivedNotes = [];

    try {
      for (final note in notes) {
        if (!note.isArchived) {
          final updatedNote = await archiveNote(note);
          archivedNotes.add(updatedNote);
        } else {
          archivedNotes.add(note);
        }
      }

      return archivedNotes;
    } catch (e) {
      throw Exception('批量归档笔记失败: $e');
    }
  }

  // 批量取消归档笔记
  Future<List<Note>> batchUnarchiveNotes(List<Note> notes) async {
    final List<Note> unarchivedNotes = [];

    try {
      for (final note in notes) {
        if (note.isArchived) {
          final updatedNote = await unarchiveNote(note);
          unarchivedNotes.add(updatedNote);
        } else {
          unarchivedNotes.add(note);
        }
      }

      return unarchivedNotes;
    } catch (e) {
      throw Exception('批量取消归档笔记失败: $e');
    }
  }
}

// 分类视图模型
@riverpod
class NoteCategoryViewModel extends _$NoteCategoryViewModel {
  late NoteDao _noteRepository;

  @override
  FutureOr<List<NoteCategory>> build() async {
    // 初始化仓库
    _noteRepository = NoteDao();

    // 加载分类列表
    return _loadCategories();
  }

  // 加载分类列表
  Future<List<NoteCategory>> _loadCategories() async {
    try {
      return await _noteRepository.getCategories();
    } catch (e) {
      throw Exception('加载分类失败: $e');
    }
  }

  // 刷新分类列表
  Future<void> refreshCategories() async {
    state = const AsyncLoading();
    try {
      final categories = await _loadCategories();
      state = AsyncValue.data(categories);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 创建分类
  Future<NoteCategory> createCategory(
    String name, {
    int? color,
    String? icon,
  }) async {
    try {
      final category = NoteCategory(name: name, color: color, icon: icon);

      final createdCategory = await _noteRepository.createCategory(category);

      // 更新状态
      state = AsyncValue.data([...state.value ?? [], createdCategory]);

      return createdCategory;
    } catch (e) {
      throw Exception('创建分类失败: $e');
    }
  }

  // 更新分类
  Future<NoteCategory> updateCategory(NoteCategory category) async {
    try {
      final updatedCategory = await _noteRepository.updateCategory(category);

      // 更新状态
      if (state.hasValue) {
        final categories = [...state.value!];
        final index = categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          categories[index] = updatedCategory;
          state = AsyncValue.data(categories);
        }
      }

      return updatedCategory;
    } catch (e) {
      throw Exception('更新分类失败: $e');
    }
  }

  // 删除分类
  Future<void> deleteCategory(int id) async {
    try {
      await _noteRepository.deleteCategory(id);

      // 更新状态
      if (state.hasValue) {
        final categories =
            state.value!.where((category) => category.id != id).toList();
        state = AsyncValue.data(categories);
      }
    } catch (e) {
      throw Exception('删除分类失败: $e');
    }
  }
}

// 标签视图模型
@riverpod
class NoteTagViewModel extends _$NoteTagViewModel {
  late NoteDao _noteRepository;

  @override
  FutureOr<List<NoteTag>> build() async {
    // 初始化仓库
    _noteRepository = NoteDao();

    // 加载标签列表
    return _loadTags();
  }

  // 加载标签列表
  Future<List<NoteTag>> _loadTags() async {
    try {
      return await _noteRepository.getTags();
    } catch (e) {
      throw Exception('加载标签失败: $e');
    }
  }

  // 刷新标签列表
  Future<void> refreshTags() async {
    state = const AsyncLoading();
    try {
      final tags = await _loadTags();
      state = AsyncValue.data(tags);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 创建标签
  Future<NoteTag> createTag(String name, {int? color}) async {
    try {
      final tag = NoteTag(name: name, color: color);

      final createdTag = await _noteRepository.createTag(tag);

      // 更新状态
      state = AsyncValue.data([...state.value ?? [], createdTag]);

      return createdTag;
    } catch (e) {
      throw Exception('创建标签失败: $e');
    }
  }

  // 更新标签
  Future<NoteTag> updateTag(NoteTag tag) async {
    try {
      final updatedTag = await _noteRepository.updateTag(tag);

      // 更新状态
      if (state.hasValue) {
        final tags = [...state.value!];
        final index = tags.indexWhere((t) => t.id == tag.id);
        if (index != -1) {
          tags[index] = updatedTag;
          state = AsyncValue.data(tags);
        }
      }

      return updatedTag;
    } catch (e) {
      throw Exception('更新标签失败: $e');
    }
  }

  // 删除标签
  Future<void> deleteTag(int id) async {
    try {
      await _noteRepository.deleteTag(id);

      // 更新状态
      if (state.hasValue) {
        final tags = state.value!.where((tag) => tag.id != id).toList();
        state = AsyncValue.data(tags);
      }
    } catch (e) {
      throw Exception('删除标签失败: $e');
    }
  }

  // 获取笔记的标签
  Future<List<NoteTag>> getTagsForNote(int noteId) async {
    try {
      return await _noteRepository.getTagsForNote(noteId);
    } catch (e) {
      throw Exception('获取笔记标签失败: $e');
    }
  }

  // 添加标签到笔记
  Future<void> addTagToNote(int noteId, int tagId) async {
    try {
      await _noteRepository.addTagToNote(noteId, tagId);
    } catch (e) {
      throw Exception('添加标签到笔记失败: $e');
    }
  }

  // 从笔记移除标签
  Future<void> removeTagFromNote(int noteId, int tagId) async {
    try {
      await _noteRepository.removeTagFromNote(noteId, tagId);
    } catch (e) {
      throw Exception('从笔记移除标签失败: $e');
    }
  }
}
