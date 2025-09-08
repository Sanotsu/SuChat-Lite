import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../data/models/one/one_base_models.dart';

/// 作者卡片组件
class AuthorCard extends StatelessWidget {
  final OneAuthor author;
  final VoidCallback? onTap;

  const AuthorCard({super.key, required this.author, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 头像
            buildUserCircleAvatar(author.webUrl, radius: 30),
            const SizedBox(width: 16),
            // 作者信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.userName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (author.desc != null)
                    Text(
                      author.desc!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // // 关注按钮
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).primaryColor,
            //     borderRadius: BorderRadius.circular(20),
            //   ),
            //   child: const Text(
            //     '关注',
            //     style: TextStyle(
            //       color: Colors.white,
            //       fontSize: 12,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
