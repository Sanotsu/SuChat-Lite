/// 账单条目实体类
class BillItem {
  /// 账单条目ID
  final int? billItemId;

  /// 账单分类
  final String category;

  /// 账单日期
  final String date;

  /// 账单时间
  final String? time;

  /// 创建/修改时间
  final String gmtModified;

  /// 账单名称
  final String item;

  /// 账单类型：0-收入，1-支出
  final int itemType;

  /// 账单金额
  final double value;

  /// 备注
  final String? remark;

  BillItem({
    this.billItemId,
    required this.category,
    required this.date,
    this.time,
    required this.gmtModified,
    required this.item,
    required this.itemType,
    required this.value,
    this.remark,
  });

  /// 从Map创建实体
  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      billItemId: map['bill_item_id'],
      category: map['category'],
      date: map['date'],
      time: map['time'],
      gmtModified: map['gmt_modified'] ?? DateTime.now().toIso8601String(),
      item: map['item'],
      itemType: map['item_type'],
      value:
          map['value'] is int ? (map['value'] as int).toDouble() : map['value'],
      remark: map['remark'],
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      if (billItemId != null) 'bill_item_id': billItemId,
      'category': category,
      'date': date,
      'time': time,
      'gmt_modified': gmtModified,
      'item': item,
      'item_type': itemType,
      'value': value,
      if (remark != null) 'remark': remark,
    };
  }

  /// 创建副本
  BillItem copyWith({
    int? billItemId,
    String? category,
    String? date,
    String? time,
    String? gmtModified,
    String? item,
    int? itemType,
    double? value,
    String? remark,
  }) {
    return BillItem(
      billItemId: billItemId ?? this.billItemId,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      gmtModified: gmtModified ?? this.gmtModified,
      item: item ?? this.item,
      itemType: itemType ?? this.itemType,
      value: value ?? this.value,
      remark: remark ?? this.remark,
    );
  }
}
