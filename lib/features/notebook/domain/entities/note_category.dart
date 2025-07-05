import 'package:flutter/material.dart';

/// 笔记分类实体类
class NoteCategory {
  final int? id;
  String name;
  // 笔记分类颜色，新版本存的是color.ARGB32()，是int
  // 转为颜色时直接 Color(color) 即可
  int? color;
  String? icon;
  int sortOrder;

  NoteCategory({
    this.id,
    required this.name,
    this.color,
    this.icon,
    this.sortOrder = 0,
  });

  // 从数据库映射创建NoteCategory对象
  factory NoteCategory.fromMap(Map<String, dynamic> map) {
    return NoteCategory(
      id: map['category_id'],
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'category_id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }

  // 创建副本
  NoteCategory copyWith({
    int? id,
    String? name,
    int? color,
    String? icon,
    int? sortOrder,
  }) {
    return NoteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // 获取分类颜色
  Color? getCategoryColor() {
    if (color != null) {
      try {
        return Color(color!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // 获取分类图标
  IconData? getCategoryIcon() {
    if (icon != null) {
      switch (icon) {
        case 'person':
          return Icons.person;
        case 'work':
          return Icons.work;
        case 'school':
          return Icons.school;
        case 'lightbulb':
          return Icons.lightbulb;
        case 'flight':
          return Icons.flight;
        case 'shopping_cart':
          return Icons.shopping_cart;
        default:
          return Icons.folder;
      }
    }
    return Icons.folder;
  }

  @override
  String toString() {
    return 'NoteCategory{id: $id, name: $name}';
  }
}
