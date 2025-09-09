import 'package:flutter/material.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../news/presentation/widgets/entrance_card.dart';
import 'random_image_page.dart';
import 'random_text_page.dart';

class FunnyStuffIndex extends StatefulWidget {
  const FunnyStuffIndex({super.key});

  @override
  State createState() => _FunnyStuffIndexState();
}

class _FunnyStuffIndexState extends State<FunnyStuffIndex> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Funny Stuff')),
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
      title: _titleWidget('趣图'),
      children: _funnyPics(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.text_fields, color: Colors.green),
      title: _titleWidget('趣文'),
      children: _funnyText(context),
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

List<Widget> _funnyPics(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: '趣图',
        subtitle: "来源:https://api.suyanw.cn/",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(context, RandomImagePage()),
      ),
    ]),
  ];
}

List<Widget> _funnyText(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: '趣文',
        subtitle: "来源:https://api.suyanw.cn/",
        onTap: () => showNoNetworkOrGoTargetPage(context, RandomTextPage()),
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
