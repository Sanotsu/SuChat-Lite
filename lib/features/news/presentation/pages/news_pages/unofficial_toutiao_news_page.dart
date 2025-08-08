import 'package:flutter/material.dart';

import '../../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../../core/utils/datetime_formatter.dart';
import '../../../../../../shared/constants/constants.dart';
import '../../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/uo_toutiao_news_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

// 注释掉的是实测无数据的分类
List<CusLabel> toutiaoNewsCategorys = [
  CusLabel(cnLabel: "推荐", value: "__all__"),
  CusLabel(cnLabel: "热点", value: "news_hot"),
  CusLabel(cnLabel: "科技", value: "news_tech"),
  // CusLabel(cnLabel: "社会", value: "news_society"),
  CusLabel(cnLabel: "娱乐", value: "news_entertainment"),
  CusLabel(cnLabel: "游戏", value: "news_game"),
  CusLabel(cnLabel: "体育", value: "news_sports"),
  CusLabel(cnLabel: "汽车", value: "news_car"),
  CusLabel(cnLabel: "财经", value: "news_finance"),
  CusLabel(cnLabel: "搞笑", value: "funny"),
  // CusLabel(cnLabel: "段子", value: "essay_joke"),
  CusLabel(cnLabel: "军事", value: "news_military"),
  CusLabel(cnLabel: "国际", value: "news_world"),
  CusLabel(cnLabel: "时尚", value: "news_fashion"),
  CusLabel(cnLabel: "旅游", value: "news_travel"),
  // CusLabel(cnLabel: "探索", value: "news_discovery"),
  CusLabel(cnLabel: "育儿", value: "news_baby"),
  CusLabel(cnLabel: "养生", value: "news_regimen"),
  CusLabel(cnLabel: "美文", value: "news_essay"),
  CusLabel(cnLabel: "历史", value: "news_history"),
  CusLabel(cnLabel: "美食", value: "news_food"),
];

///
/// 头条新闻
/// https://github.com/Meowv/ToutiaoNews
/// 没有分页，只能看到一点点
///
class UnofficialToutiaoNewsPage extends StatefulWidget {
  const UnofficialToutiaoNewsPage({super.key});

  @override
  State<UnofficialToutiaoNewsPage> createState() =>
      _UnofficialToutiaoNewsPageState();
}

class _UnofficialToutiaoNewsPageState
    extends BaseNewsPageState<UnofficialToutiaoNewsPage, UoToutiaoNews> {
  // 热门内容的分页时间锚点，类似微博、今日头条等推荐系统，用于控制“加载更多”时的时间范围
  // 下次请求时，客户端带上 ?max_behot_time=xxx，以获取更早的热门内容（类似分页）。
  int? maxBehotTime;

  @override
  List<CusLabel> getCategories() => toutiaoNewsCategorys;

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
      // 如果是第一页或者往下拉加载最新数据时，不要传时间戳
      UoToutiaoNewsResp htRst = currentPage == 1
          ? await newsApiManager.getUoToutiaoNewsList(
              category: (selectedNewsCategory.value as String),
              forceRefresh: true,
            )
          : await newsApiManager.getUoToutiaoNewsList(
              category: (selectedNewsCategory.value as String),
              maxBehotTime: maxBehotTime,
              forceRefresh: true,
            );

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          newsList = htRst.data ?? [];
        } else {
          newsList.addAll(htRst.data ?? []);
        }

        // 这个API没看到分页参数，暂时就当作只有1页
        hasMore = htRst.hasMore ?? false;
        maxBehotTime = htRst.next?.maxBehotTime;

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
  Widget buildNewsCard(UoToutiaoNews item, int index) {
    // 源地址是头条的相对路径，所以拼接
    var url = "";
    if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty) {
      url = "https://www.toutiao.com/${item.sourceUrl}";
    }

    return CoverNewsCard(
      title: "${(item.isStick ?? false) ? '[置顶]' : ''} ${item.title ?? ''} ",
      summary: item.abstract ?? '',
      url: url,
      // 新闻图片无法加载，这里使用媒体头像
      imageUrl: item.mediaAvatarUrl ?? '',
      source: item.source ?? '',
      author: item.source ?? '',
      // 源网页显示的是发布时间而不是修改时间
      publishedAt: formatTimestampToString(item.behotTime?.toString()),
      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '头条新闻';

  @override
  String getInfoMessage() =>
      """数据来源：Github [Meowv/ToutiaoNews](https://github.com/Meowv/ToutiaoNews)\n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
