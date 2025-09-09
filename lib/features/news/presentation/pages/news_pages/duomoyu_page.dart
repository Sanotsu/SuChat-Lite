import 'package:flutter/material.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/duomoyu_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

List<CusLabel> duomoyuCategorys = [
  // 社区
  CusLabel(cnLabel: "知乎", value: "zhihu"),
  CusLabel(cnLabel: "虎扑", value: "hupu"),
  CusLabel(cnLabel: "V2EX", value: "2ex"),
  CusLabel(cnLabel: "NGA", value: "ngabbs"),
  CusLabel(cnLabel: "IT 之家『喜加一』", value: "ithome-xijiayi"),
  CusLabel(cnLabel: "NodeSeek", value: "nodeseek"),
  // 新闻
  CusLabel(cnLabel: "澎湃新闻", value: "thepaper"),
  CusLabel(cnLabel: "百度", value: "baidu"),
  CusLabel(cnLabel: "今日头条", value: "toutiao"),
  CusLabel(cnLabel: "腾讯新闻", value: "qq-news"),
  CusLabel(cnLabel: "网易新闻", value: "netease-news"),
  // 娱乐
  CusLabel(cnLabel: "微博", value: "weibo"),
  CusLabel(cnLabel: "抖音", value: "douyin"),
  CusLabel(cnLabel: "哔哩哔哩", value: "bilibili"),
  CusLabel(cnLabel: "豆瓣电影", value: "douban-movie"),
  CusLabel(cnLabel: "豆瓣讨论小组", value: "douban-group"),
  // 科技
  CusLabel(cnLabel: "IT 之家", value: "ithome"),
  CusLabel(cnLabel: "36 氪", value: "36kr"),
  CusLabel(cnLabel: "少数派", value: "sspai"),
  // 开发
  CusLabel(cnLabel: "稀土掘金", value: "juejin"),
  CusLabel(cnLabel: "HelloGitHub", value: "hellogithub"),
  CusLabel(cnLabel: "51CTO", value: "51cto"),
];

class DuomoyuPage extends StatefulWidget {
  const DuomoyuPage({super.key});

  @override
  State<DuomoyuPage> createState() => _DuomoyuPageState();
}

class _DuomoyuPageState extends BaseNewsPageState<DuomoyuPage, DuomoyuData> {
  @override
  List<CusLabel> getCategories() => duomoyuCategorys;

  // isRefresh 是上下拉的时候的刷新，初始化进入页面时就为false，展示加载圈位置不一样
  @override
  Future<void> fetchNewsData({bool isRefresh = false}) async {
    if (isRefresh) {
      if (isRefreshLoading) return;
      setState(() {
        isRefreshLoading = true;
      });
    } else {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });
    }

    try {
      DuomoyuResp htRst = await newsApiManager.getDuomoyuList(
        category: (selectedNewsCategory.value as String),
      );

      if (!mounted) return;
      setState(() {
        newsList = htRst.data ?? [];
        lastTime = htRst.updateTime;
        // 多摸鱼是热榜，没有分页
        hasMore = false;

        // 重新加载新闻列表都是未加载的状态
        isExpandedList = List.generate(newsList.length, (index) => false);
      });
    } on CusHttpException catch (e) {
      // API请求报错，显示报错信息
      // http连接相关的报错在拦截器就有弹窗报错了，这里暂时不显示了
      // showSnackMessage(context, e.cusMsg);
      debugPrint(e.toString());
    } catch (e) {
      ToastUtils.showError(e.toString());
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isRefresh ? isRefreshLoading = false : isLoading = false;
        });
      }
    }
  }

  @override
  Widget buildNewsCard(DuomoyuData item, int index) {
    return CoverNewsCard(
      title: item.title ?? '',
      summary: item.desc ?? '',
      url: item.url ?? '',
      imageUrl: item.cover ?? '',
      source: selectedNewsCategory.cnLabel,
      author: selectedNewsCategory.cnLabel,
      // 源网页显示的是发布时间而不是修改时间
      publishedAt: formatTimestampToString(item.timestamp?.toString()),
      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '多摸鱼';

  @override
  String getInfoMessage() =>
      """数据来源：[多摸鱼](https://duomoyu.com/)\n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
