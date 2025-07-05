import 'package:flutter/material.dart';

import 'note_category.dart';
import 'note_media.dart';
import 'note_tag.dart';

/// 笔记实体类
class Note {
  int? id;
  String title;
  String content;
  String contentDelta; // 富文本Delta格式
  int? categoryId;
  NoteCategory? category;
  bool isTodo;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;
  // 笔记颜色，新版本存的是color.ARGB32()，是int
  // 转为颜色时直接 Color(color) 即可
  int? color;
  bool isPinned;
  bool isArchived;
  DateTime? reminderTime;
  List<NoteTag> tags;
  List<NoteMedia> mediaList;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.contentDelta,
    this.categoryId,
    this.category,
    this.isTodo = false,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.color,
    this.isPinned = false,
    this.isArchived = false,
    this.reminderTime,
    List<NoteTag>? tags,
    List<NoteMedia>? mediaList,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       tags = tags ?? [],
       mediaList = mediaList ?? [];

  // 从数据库映射创建Note对象
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['note_id'],
      title: map['title'],
      content: map['content'],
      contentDelta: map['content_delta'],
      categoryId: map['category_id'],
      isTodo: map['is_todo'] == 1,
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      color: map['color'],
      isPinned: map['is_pinned'] == 1,
      isArchived: map['is_archived'] == 1,
      reminderTime:
          map['reminder_time'] != null
              ? DateTime.parse(map['reminder_time'])
              : null,
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'note_id': id,
      'title': title,
      'content': content,
      'content_delta': contentDelta,
      'category_id': categoryId,
      'is_todo': isTodo ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'reminder_time': reminderTime?.toIso8601String(),
    };
  }

  // 创建副本
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? contentDelta,
    int? categoryId,
    NoteCategory? category,
    bool? isTodo,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? color,
    bool? isPinned,
    bool? isArchived,
    DateTime? reminderTime,
    List<NoteTag>? tags,
    List<NoteMedia>? mediaList,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentDelta: contentDelta ?? this.contentDelta,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      isTodo: isTodo ?? this.isTodo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      reminderTime: reminderTime ?? this.reminderTime,
      tags: tags ?? List.from(this.tags),
      mediaList: mediaList ?? List.from(this.mediaList),
    );
  }

  // 获取笔记颜色
  Color? getNoteColor() {
    if (color != null) {
      try {
        return Color(color!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Note{id: $id, title: $title, content: $content}';
  }
}
