import 'package:flutter/material.dart';

import '../../../../../../core/utils/datetime_formatter.dart';
import '../../../../../../shared/constants/constants.dart';
import '../../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../data/models/one/one_category_list.dart';

/// 小记卡片组件
class OneDiaryCard extends StatelessWidget {
  final OneDiary diary;
  final VoidCallback? onTap;

  const OneDiaryCard({super.key, required this.diary, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // 注意，如果是放在了 GridView 里面，这里的高度设定似乎用处不大
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // 背景图片
                    Container(
                      height: 160, // 图片区域高度
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: (diary.imgUrlThumb != null || diary.imgUrl != null)
                          ? buildNetworkOrFileImage(
                              diary.imgUrlThumb ?? diary.imgUrl ?? '',
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported, size: 48),
                    ),

                    // 标签
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '小记',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    diary.content ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  if (diary.user != null)
                    Text(
                      diary.user?.userName ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (diary.inputDate != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDateTimeString(
                              diary.inputDate!,
                              formatType: formatToYMD,
                            ),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 点赞数
                        if (diary.praisenum != null)
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 16,
                                color: Colors.red[300],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${diary.praisenum}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
