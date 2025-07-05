import 'package:flutter/material.dart';

import '../../core/utils/screen_helper.dart';

class ModernFeatureCard extends StatelessWidget {
  final Widget targetPage;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final bool showArrow;
  final bool showSubtitle;

  const ModernFeatureCard({
    super.key,
    required this.targetPage,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    this.showArrow = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenHelper.isDesktop();

    final theme = Theme.of(context);
    final textColor = theme.textTheme.titleLarge?.color ?? Colors.black;
    final color = accentColor ?? theme.primaryColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => targetPage));
        },
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 8),
          child: Row(
            children: [
              // 左侧图标
              Container(
                width: isDesktop ? 56 : 48,
                height: isDesktop ? 56 : 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),

              SizedBox(width: 16),

              // 中间文本
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (showSubtitle)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // 右侧箭头
              if (showArrow) ...[
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
