import 'package:flutter/material.dart';

import '../../core/utils/screen_helper.dart';

class FeatureGridCard extends StatelessWidget {
  final Widget targetPage;
  final String title;
  final IconData icon;
  final Color? accentColor;
  final bool isNew;
  // 组合是否新功能，但可以自定义显示内容
  final String? newLabel;

  const FeatureGridCard({
    super.key,
    required this.targetPage,
    required this.title,
    required this.icon,
    this.accentColor,
    this.isNew = false,
    this.newLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).primaryColor;
    final isDesktop = ScreenHelper.isDesktop();

    return Card(
      elevation: 0,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => targetPage));
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(isDesktop ? 16 : 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: isDesktop ? 64 : 40,
                    height: isDesktop ? 64 : 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: isDesktop ? 32 : 24),
                  ),
                  SizedBox(height: isDesktop ? 16 : 4),

                  // ??? 为什么这个居中整个卡片的内容都居中了？
                  Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: isDesktop ? 8 : 4,
                right: isDesktop ? 8 : 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : 4,
                    vertical: isDesktop ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    newLabel ?? '新',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 12 : 8,
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
