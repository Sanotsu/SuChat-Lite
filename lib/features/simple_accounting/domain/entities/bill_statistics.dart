/// 账单统计实体类
class BillStatistics {
  /// 总收入
  final double totalIncome;

  /// 总支出
  final double totalExpense;

  /// 净收入（收入-支出）
  final double netIncome;

  /// 按日期分组的收入 Map<日期字符串, 金额>
  final Map<String, double> incomeByDate;

  /// 按日期分组的支出 Map<日期字符串, 金额>
  final Map<String, double> expenseByDate;

  /// 按分类分组的收入 Map<分类名称, 金额>
  final Map<String, double> incomeByCategory;

  /// 按分类分组的支出 Map<分类名称, 金额>
  final Map<String, double> expenseByCategory;

  /// 构造函数
  const BillStatistics({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.netIncome = 0,
    this.incomeByDate = const {},
    this.expenseByDate = const {},
    this.incomeByCategory = const {},
    this.expenseByCategory = const {},
  });

  /// 创建空的统计对象
  factory BillStatistics.empty() {
    return const BillStatistics();
  }

  /// 复制并修改部分属性
  BillStatistics copyWith({
    double? totalIncome,
    double? totalExpense,
    double? netIncome,
    Map<String, double>? incomeByDate,
    Map<String, double>? expenseByDate,
    Map<String, double>? incomeByCategory,
    Map<String, double>? expenseByCategory,
  }) {
    return BillStatistics(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      netIncome: netIncome ?? this.netIncome,
      incomeByDate: incomeByDate ?? this.incomeByDate,
      expenseByDate: expenseByDate ?? this.expenseByDate,
      incomeByCategory: incomeByCategory ?? this.incomeByCategory,
      expenseByCategory: expenseByCategory ?? this.expenseByCategory,
    );
  }

  /// 获取支出分类占比
  Map<String, double> getExpenseCategoryPercentage() {
    if (totalExpense == 0) return {};

    Map<String, double> result = {};
    expenseByCategory.forEach((key, value) {
      result[key] = (value / totalExpense) * 100;
    });
    return result;
  }

  /// 获取收入分类占比
  Map<String, double> getIncomeCategoryPercentage() {
    if (totalIncome == 0) return {};

    Map<String, double> result = {};
    incomeByCategory.forEach((key, value) {
      result[key] = (value / totalIncome) * 100;
    });
    return result;
  }

  /// 获取最大支出分类
  String? getTopExpenseCategory() {
    if (expenseByCategory.isEmpty) return null;

    String topCategory = '';
    double maxValue = 0;

    expenseByCategory.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
        topCategory = key;
      }
    });

    return topCategory;
  }

  /// 获取最大收入分类
  String? getTopIncomeCategory() {
    if (incomeByCategory.isEmpty) return null;

    String topCategory = '';
    double maxValue = 0;

    incomeByCategory.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
        topCategory = key;
      }
    });

    return topCategory;
  }

  @override
  String toString() {
    return '''
    BillStatistics { 
      "totalIncome": $totalIncome,
      "totalExpense": $totalExpense,
      "netIncome": $netIncome,
      "incomeByDate": $incomeByDate,
      "expenseByDate": $expenseByDate,
      "incomeByCategory": $incomeByCategory,
      "expenseByCategory": $expenseByCategory
    }
    ''';
  }
}
