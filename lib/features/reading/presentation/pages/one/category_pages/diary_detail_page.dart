import 'package:flutter/material.dart';

import '../../../../../../core/utils/datetime_formatter.dart';
import '../../../../../../core/utils/get_dir.dart';
import '../../../../../../core/utils/simple_tools.dart';
import '../../../../../../shared/constants/constants.dart';
import '../../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../data/models/one/one_category_list.dart';

/// 小记详情页面
class DiaryDetailPage extends StatelessWidget {
  final OneDiary diary;
  final VoidCallback? onTap;

  const DiaryDetailPage({super.key, required this.diary, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小记详情'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (diary.picture != null && diary.picture!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async {
                // 网络图片就保存都指定位置
                await saveImageToLocal(
                  diary.picture!,
                  imageName: "ONE一个_小记_${fileTs(DateTime.now())}.jpg",
                  dlDir: await getAppHomeDirectory(subfolder: "NET_DL/one"),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(child: buildBody()),
    );
  }

  Widget buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 背景图片
        Container(
          width: double.infinity,
          color: Colors.grey[200],
          child: (diary.imgUrl != null || diary.imgUrlThumb != null)
              ? buildNetworkOrFileImage(
                  diary.imgUrl ?? diary.imgUrlThumb ?? '',
                  fit: BoxFit.fitWidth,
                )
              : const Icon(Icons.image_not_supported, size: 48),
        ),

        buildTextArea(),
      ],
    );
  }

  Widget buildTextArea() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间、地点
          Row(
            children: [
              Text(
                formatDateTimeString(diary.inputDate, formatType: formatToYMD),
                style: TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              Text(
                " | ${diary.addr ?? ''}",
                style: TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              Spacer(),

              Text(
                diary.weather ?? '',
                style: TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          const SizedBox(height: 16),
          SelectableText(diary.content ?? ''),
          const SizedBox(height: 16),

          Row(
            children: [
              if (diary.user != null)
                Expanded(
                  child: Row(
                    children: [
                      // 用户头像
                      buildUserCircleAvatar(diary.user?.webUrl, radius: 12),
                      const SizedBox(width: 12),
                      Text(
                        diary.user?.userName ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
