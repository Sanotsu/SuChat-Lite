import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/screen_helper.dart';

/// 入口卡片
class EntranceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? imageUrl;
  final Widget? targetPage;
  final void Function()? onTap;

  const EntranceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imageUrl,
    this.iconColor = Colors.blue,
    this.targetPage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).canvasColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        // 如果有传目标页面，直接跳转，不管有没有onTap函数；如果没有目标页面，再执行onTap操作
        onTap: (targetPage != null)
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => targetPage!),
                );
              }
            : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenHelper.isDesktop() ? 20 : 4,
          ),
          child: Row(
            children: [
              imageUrl != null
                  ? CircularNetworkImage(imageUrl: imageUrl!)
                  : CircleAvatar(
                      backgroundColor: iconColor,
                      radius: 16,
                      child: Icon(
                        icon ?? Icons.newspaper,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle ?? "",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color backgroundColor;

  const CircularNetworkImage({
    super.key,
    required this.imageUrl,
    this.radius = 16,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }
}
