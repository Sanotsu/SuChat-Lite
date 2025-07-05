import 'package:flutter/material.dart';

/// 笔记标签实体类
class NoteTag {
  final int? id;
  String name;
  // 笔记标签颜色，新版本存的是color.ARGB32()，是int
  // 转为颜色时直接 Color(color) 即可
  int? color;

  NoteTag({this.id, required this.name, this.color});

  // 从数据库映射创建NoteTag对象
  factory NoteTag.fromMap(Map<String, dynamic> map) {
    return NoteTag(id: map['tag_id'], name: map['name'], color: map['color']);
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {if (id != null) 'tag_id': id, 'name': name, 'color': color};
  }

  // 创建副本
  NoteTag copyWith({int? id, String? name, int? color}) {
    return NoteTag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  // 获取标签颜色
  Color? getTagColor() {
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
    return 'NoteTag{id: $id, name: $name}';
  }
}
