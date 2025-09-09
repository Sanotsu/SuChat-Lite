import 'package:flutter/material.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../news/presentation/widgets/entrance_card.dart';
import 'bangumi/calendar_page.dart';
import 'my_anime_list/top_page.dart';
import 'waifu_pics/index.dart';

///
/// 后续动画、漫画、二次元、电影剧集真人秀、游戏等，都放在这个分类里面
/// 2025-08-18 TMDB 内容丰富，单独一个入口
///
class VisualMediaIndex extends StatefulWidget {
  const VisualMediaIndex({super.key});

  @override
  State createState() => _VisualMediaIndexState();
}

class _VisualMediaIndexState extends State<VisualMediaIndex> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('动漫资讯')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 功能入口按钮
          Expanded(
            child: ListView(
              children: [
                /// 这个是分类的折叠栏
                ...buildExpansionTileList(context),
              ],
            ),
          ),

          Text(
            "数据来源若侵权，请及时联系我删除",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// 可折叠分类显示
List<Widget> buildExpansionTileList(BuildContext context) {
  return [
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.image, color: Colors.green),
      title: _titleWidget('动画和漫画'),
      children: _animeAndComics(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.text_fields, color: Colors.green),
      title: _titleWidget('二次元图片'),
      children: _waifuImage(context),
    ),
    const Divider(),
  ];
}

// 分类的标题文字组件
Widget _titleWidget(String title, {IconData? iconData}) {
  return Padding(
    padding: EdgeInsets.all(5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (iconData != null) Icon(iconData, color: Colors.green),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.green,
          ),
        ),
      ],
    ),
  );
}

List<Widget> _animeAndComics(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: 'BGM动漫资讯',
        subtitle: "Bangumi番组计划",
        icon: Icons.newspaper,
        onTap: () =>
            showNoNetworkOrGoTargetPage(context, BangumiCalendarPage()),
      ),
      EntranceCard(
        title: 'MAL动漫排行',
        subtitle: "MyAnimeList排行榜",
        onTap: () => showNoNetworkOrGoTargetPage(context, MALTopPage()),
      ),
    ]),
  ];
}

List<Widget> _waifuImage(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: 'WAIFU图片',
        subtitle: "随机二次元WAIFU",
        onTap: () => showNoNetworkOrGoTargetPage(context, WaifuPicIndex()),
      ),
    ]),
  ];
}

// 分类中的组件入口列表
Widget _rowWidget(List<Widget> children) {
  return SizedBox(
    height: 80,
    child: Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    ),
  );
}
