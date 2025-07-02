import 'package:flutter/material.dart';

/// 账单分类实体类
class BillCategory {
  /// 分类ID
  final int? id;

  /// 分类名称
  final String name;

  /// 分类图标
  final String? icon;

  /// 分类颜色
  final String? color;

  /// 分类类型：0-收入，1-支出
  final int type;

  /// 是否为默认分类
  final int isDefault;

  BillCategory({
    this.id,
    required this.name,
    this.icon,
    this.color,
    required this.type,
    this.isDefault = 0,
  });

  /// 从Map创建实体
  factory BillCategory.fromMap(Map<String, dynamic> map) {
    return BillCategory(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
      isDefault: map['is_default'] ?? 0,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault,
    };
  }

  /// 创建副本
  BillCategory copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? type,
    int? isDefault,
  }) {
    return BillCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// 获取图标
  /// 根据分类名称获取对应的图标
  IconData getIconData() {
    // 支出分类图标
    switch (name) {
      case '餐饮':
        return Icons.restaurant;
      case '交通':
        return Icons.directions_bus;
      case '购物':
        return Icons.shopping_cart;
      case '服饰':
        return Icons.checkroom;
      case '日用':
        return Icons.home;
      case '住房':
        return Icons.house;

      case '娱乐':
        return Icons.movie;
      case '缴费':
        return Icons.payment;
      case '数码':
        return Icons.devices;
      case '运动':
        return Icons.directions_run;
      case '旅行':
        return Icons.flight;
      case '宠物':
        return Icons.pets;

      case '教育':
        return Icons.school;
      case '医疗':
        return Icons.local_hospital;
      case '红包': // 支出收入都有的
        return Icons.redeem;
      case '转账': // 支出收入都有的
        return Icons.swap_horiz;
      case '人情': // 支出收入都有的
        return Icons.people;
      case '轻奢':
        return Icons.shopping_cart;

      case '美容':
        return Icons.face;
      case '亲子':
        return Icons.child_care;
      case '保险':
        return Icons.security;
      case '公益':
        return Icons.volunteer_activism;
      case '服务':
        return Icons.build;

      case '通讯':
        return Icons.phone;
      case '汽车':
        return Icons.directions_car;
      case '办公':
        return Icons.work;
      case '维修':
        return Icons.build;

      // 收入分类图标
      case '工资':
        return Icons.monetization_on;
      case '奖金':
        return Icons.card_giftcard;
      case '生意':
        return Icons.store;
      case '兼职':
        return Icons.work_outline;
      case '投资':
        return Icons.account_balance;
      case '炒股':
        return Icons.trending_up;
      case '基金':
        return Icons.trending_up;
      case '退款':
        return Icons.assignment_return;
      case '报销':
        return Icons.receipt;

      // 默认图标
      default:
        return type == 0 ? Icons.add_circle : Icons.remove_circle;
    }
  }

  /// 获取颜色
  Color getColor() {
    // 将十六进制颜色字符串转换为Color对象
    try {
      if (color == null) {
        return Colors.grey;
      }
      final hexColor = color!.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
