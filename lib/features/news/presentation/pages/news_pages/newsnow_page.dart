import 'package:flutter/material.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/news_now_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

// 原项目有很多新闻源，这里只列出了部分
// https://newsnow.busiyi.world/
// https://github.com/ourongxing/newsnow/blob/main/shared/sources.json
List<CusLabel> newsnowCategorys = [
  CusLabel(cnLabel: "知乎", value: "zhihu"),
  CusLabel(cnLabel: "微博", value: "weibo"),
  CusLabel(cnLabel: "酷安", value: "coolapk"),
  CusLabel(cnLabel: "华尔街见闻", value: "wallstreetcn-hot"),

  CusLabel(cnLabel: "抖音", value: "douyin"),
  CusLabel(cnLabel: "虎扑", value: "hupu"),
  CusLabel(cnLabel: "百度贴吧", value: "tieba"),
  CusLabel(cnLabel: "今日头条", value: "toutiao"),

  CusLabel(cnLabel: "澎湃新闻", value: "thepaper"),
  CusLabel(cnLabel: "财联社", value: "cls-hot"),
  CusLabel(cnLabel: "百度", value: "baidu"),
  CusLabel(cnLabel: "哔哩哔哩", value: "bilibili-hot-search"),

  CusLabel(cnLabel: "牛客", value: "nowcoder"),
  CusLabel(cnLabel: "稀土掘金", value: "juejin"),
  CusLabel(cnLabel: "Hacker News", value: "hackernews"),
  CusLabel(cnLabel: "GitHub Today", value: "github-trending-today"),
  CusLabel(cnLabel: "Product Hunt", value: "producthunt"),

  CusLabel(cnLabel: "雪球", value: "xueqiu-hotstock"),
  CusLabel(cnLabel: "虫部落-最热", value: "chongbuluo-hot"),
  CusLabel(cnLabel: "虫部落-最新", value: "chongbuluo-latest"),
  CusLabel(cnLabel: "凤凰网", value: "ifeng"),
  CusLabel(cnLabel: "少数派", value: "sspai"),

  // 从github中加入的源，原网页没有加这些
  CusLabel(cnLabel: "IT之家", value: "ithome"),
  CusLabel(cnLabel: "V2EX", value: "v2ex"),
  CusLabel(cnLabel: "联合早报", value: "zaobao"),
  CusLabel(cnLabel: "MKTNews", value: "mktnews"),
  CusLabel(cnLabel: "36氪", value: "36kr-quick"),
  CusLabel(cnLabel: "卫星通讯社", value: "sputniknewscn"),
  CusLabel(cnLabel: "参考消息", value: "cankaoxiaoxi"),
  CusLabel(cnLabel: "远景论坛", value: "pcbeta-windows11"),
  CusLabel(cnLabel: "财联社-电报", value: "cls-telegraph"),
  CusLabel(cnLabel: "财联社-深度", value: "cls-depth"),
  CusLabel(cnLabel: "格隆汇", value: "gelonghui"),
  CusLabel(cnLabel: "法布财经-快讯", value: "fastbull-express"),
  CusLabel(cnLabel: "法布财经-头条", value: "fastbull-news"),
  CusLabel(cnLabel: "Solidot", value: "solidot"),
  CusLabel(cnLabel: "快手", value: "kuaishou"),
  CusLabel(cnLabel: "靠谱新闻", value: "kaopu"),
  CusLabel(cnLabel: "金十数据", value: "jin10"),
];

class NewsNowPage extends StatefulWidget {
  const NewsNowPage({super.key});

  @override
  State<NewsNowPage> createState() => _NewsNowPageState();
}

class _NewsNowPageState extends BaseNewsPageState<NewsNowPage, NewsNowItem> {
  @override
  List<CusLabel> getCategories() => newsnowCategorys;

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
      NewsNowResp htRst = await newsApiManager.getNewsNowList(
        id: (selectedNewsCategory.value as String),
      );

      if (!mounted) return;
      setState(() {
        newsList = htRst.items ?? [];
        lastTime = formatTimestampToString(htRst.updatedTime.toString());
        // 热榜，没有分页
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
  Widget buildNewsCard(NewsNowItem item, int index) {
    return CoverNewsCard(
      title: item.title ?? '',
      summary: item.extra?.hover ?? '',
      url: item.mobileUrl ?? item.url ?? '',
      source: selectedNewsCategory.cnLabel,
      author: "${selectedNewsCategory.cnLabel}  ${item.extra?.info ?? ''}",

      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => 'News Now';

  @override
  String getInfoMessage() =>
      """数据来源：[News Now](https://newsnow.busiyi.world/)\n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
