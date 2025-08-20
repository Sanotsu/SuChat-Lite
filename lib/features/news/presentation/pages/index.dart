import 'package:flutter/material.dart';

import '../../../../shared/services/network_service.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../data/datasources/hitokoto_apis.dart';
import '../../data/models/hitokoto.dart';
import '../widgets/entrance_card.dart';
import 'news_pages/baike_history_in_today_page.dart';
import 'news_pages/duomoyu_page.dart';
import 'news_pages/jiqizhixin_page.dart';
import 'news_pages/momoyu_page.dart';
import 'news_pages/newsapi_page.dart';
import 'news_pages/newsnow_page.dart';
import 'news_pages/readhub_page.dart';
import 'news_pages/sina_roll_news_page.dart';
import 'news_pages/daily_60s_page.dart';
import 'news_pages/unofficial_ithome_page.dart';
import 'news_pages/sut_bbc_news_page.dart';
import 'news_pages/unofficial_toutiao_news_page.dart';
import 'base_news_page/paper_news_image_page.dart';
import 'news_pages/uo_zhihu_daily_page.dart';

class NewsIndex extends StatefulWidget {
  const NewsIndex({super.key});

  @override
  State createState() => _NewsIndexState();
}

class _NewsIndexState extends State<NewsIndex> {
  Hitokoto? hito;

  @override
  void initState() {
    getOneSentence();
    super.initState();
  }

  // 2024-10-17 注意，请求太过频繁会无法使用
  Future<void> getOneSentence() async {
    // 如果没网，就不查询一言了
    bool isNetworkAvailable = await NetworkStatusService().isNetwork();

    if (!mounted) return;
    if (!isNetworkAvailable) {
      setState(() {
        hito = null;
      });
      return;
    }

    var a = await getHitokoto();

    if (!mounted) return;
    setState(() {
      hito = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('新闻热榜')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 显示一言
          buildHitokoto(),
          const Divider(),

          /// 功能入口按钮
          Expanded(
            child: ListView(
              children: [
                // ...newsSourceList(context),
                // /// 这个是分类的折叠栏
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

  Widget buildHitokoto() {
    return hito != null
        ? SizedBox(
            height: 80,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: hito?.hitokoto ?? '',
                      style: TextStyle(color: Colors.blue, fontSize: 15),
                    ),
                    // 第二行文本，靠右对齐
                    WidgetSpan(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "\n——${hito?.fromWho ?? ''}「${hito?.from ?? ''}」",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : SizedBox(height: 80, child: Text('<暂无网络>'));
  }
}

/// 可折叠分类显示
List<Widget> buildExpansionTileList(BuildContext context) {
  return [
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.newspaper, color: Colors.green),
      title: _titleWidget('热点聚合'),
      children: _hotNewsSites(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.newspaper, color: Colors.green),
      title: _titleWidget('来源官网'),
      children: _officialSite(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.newspaper, color: Colors.green),
      title: _titleWidget('图片新闻'),
      children: _imageNews(context),
    ),
    const Divider(),

    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.newspaper, color: Colors.green),
      title: _titleWidget('野版数源'),
      children: _unofficialSite(context),
    ),
    const Divider(),
    ExpansionTile(
      shape: const Border(),
      leading: const Icon(Icons.newspaper, color: Colors.green),
      title: _titleWidget('需要科技'),
      children: _outerNewsSite(context),
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

List<Widget> _hotNewsSites(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: '摸摸鱼',
        subtitle: "聚合新闻摸鱼网站",

        imageUrl: "https://momoyu.cc/assets/logo-1-DXR4uO3F.png",
        onTap: () => showNoNetworkOrGoTargetPage(context, MomoyuPage()),
      ),

      EntranceCard(
        title: '多摸鱼',
        subtitle: "摸鱼效率提升利器",
        imageUrl: "https://duomoyu.com/favicon.ico",
        onTap: () => showNoNetworkOrGoTargetPage(context, DuomoyuPage()),
      ),
    ]),

    _rowWidget([
      EntranceCard(
        title: 'News Now',
        subtitle: "优雅地阅读实时热点",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(context, NewsNowPage()),
      ),

      SizedBox(width: 10),
    ]),
  ];
}

List<Widget> _officialSite(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: 'Readhub',
        subtitle: "高效、优质、个性化",
        imageUrl: "https://readhub.cn/favicon.ico",
        onTap: () => showNoNetworkOrGoTargetPage(context, ReadHubPage()),
      ),

      EntranceCard(
        title: '新浪新闻',
        subtitle: "新闻中心滚动新闻",
        imageUrl: "https://feed.mix.sina.com.cn/favicon.ico",
        onTap: () => showNoNetworkOrGoTargetPage(context, SinaRollNewsPage()),
      ),
    ]),

    _rowWidget([
      EntranceCard(
        title: '机器之心',
        subtitle: "追踪 AI 发展",
        imageUrl: "https://www.jiqizhixin.com/favicon.ico",
        onTap: () => showNoNetworkOrGoTargetPage(context, JiqizhixinPage()),
      ),

      SizedBox(width: 10),
    ]),
  ];
}

List<Widget> _imageNews(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: '每天60秒',
        subtitle: "每天60秒读懂世界",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(context, Daily60SPage()),
      ),
      EntranceCard(
        title: '人民日报',
        subtitle: "人民日报报纸图片",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          PaperNewsImagePage(
            title: '人民日报',
            imageUrl: 'https://api.suyanw.cn/api/rmrb.php',
          ),
        ),
      ),
    ]),
    _rowWidget([
      EntranceCard(
        title: '新华日报',
        subtitle: "新华日报报纸图片",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          PaperNewsImagePage(
            title: '新华日报',
            imageUrl: 'https://api.suyanw.cn/api/xhrb.php',
          ),
        ),
      ),
      EntranceCard(
        title: '南方日报',
        subtitle: "南方日报报纸图片",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          PaperNewsImagePage(
            title: '南方日报',
            imageUrl: 'https://api.suyanw.cn/api/nfrb.php',
          ),
        ),
      ),
    ]),
  ];
}

List<Widget> _unofficialSite(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: 'IT之家',
        subtitle: "IT之家最新新闻",
        icon: Icons.newspaper,
        onTap: () =>
            showNoNetworkOrGoTargetPage(context, UnofficialITHomePage()),
      ),

      EntranceCard(
        title: '头条新闻',
        subtitle: "头条新闻热榜",
        icon: Icons.newspaper,
        onTap: () =>
            showNoNetworkOrGoTargetPage(context, UnofficialToutiaoNewsPage()),
      ),
    ]),
    _rowWidget([
      EntranceCard(
        title: '知乎日报',
        subtitle: "不完整的知乎日报",
        icon: Icons.newspaper,
        onTap: () =>
            showNoNetworkOrGoTargetPage(context, UnofficialZhihuDailyPage()),
      ),

      EntranceCard(
        title: '历史上的今天',
        subtitle: "来源于百度百科",
        icon: Icons.newspaper,
        onTap: () =>
            showNoNetworkOrGoTargetPage(context, BaikeHistoryInTodayPage()),
      ),
    ]),
  ];
}

List<Widget> _outerNewsSite(BuildContext context) {
  return [
    _rowWidget([
      EntranceCard(
        title: 'NewsAPI',
        subtitle: "NewsAPI新闻资讯",
        imageUrl: "https://newsapi.org/favicon-32x32.png",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(context, NewsApiPage()),
      ),
      EntranceCard(
        title: 'BBC News',
        subtitle: "BBC新闻资讯",
        icon: Icons.newspaper,
        onTap: () => showNoNetworkOrGoTargetPage(context, SutBbcNewsRespPage()),
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

/// 卡片在没有网的时候，点击就显示弹窗；有网才跳转到功能页面
void showNoNetworkOrGoTargetPage(
  BuildContext context,
  Widget targetPage,
) async {
  bool isNetworkAvailable = await NetworkStatusService().isNetwork();

  if (!context.mounted) return;
  isNetworkAvailable
      ? Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        )
      : commonHintDialog(context, "提示", "请联网后使用该功能。", msgFontSize: 15);
}
