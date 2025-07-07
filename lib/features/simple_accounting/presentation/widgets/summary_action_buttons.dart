import 'package:flutter/material.dart';

/// 汇总操作按钮组件
class SummaryActionButtons extends StatelessWidget {
  /// 按月汇总点击回调
  final VoidCallback onMonthlySummary;

  /// 按年汇总点击回调
  final VoidCallback onYearlySummary;

  /// 当前选中的汇总类型：null-未选择，monthly-按月汇总，yearly-按年汇总
  final String? selectedSummaryType;

  const SummaryActionButtons({
    super.key,
    required this.onMonthlySummary,
    required this.onYearlySummary,
    this.selectedSummaryType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '历史汇总',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildSummaryButton(
                context,
                '按月汇总',
                Icons.calendar_month,
                selectedSummaryType == 'monthly',
                onMonthlySummary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryButton(
                context,
                '按年汇总',
                Icons.calendar_today,
                selectedSummaryType == 'yearly',
                onYearlySummary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建汇总按钮
  Widget _buildSummaryButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);

    return Material(
      color:
          isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
