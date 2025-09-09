import 'package:flutter/material.dart';

import '../../../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../../../shared/constants/constants.dart';
import '../../../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/sut_bbc_news_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

// 注释掉的是实测无数据的分类
List<CusLabel> langCategorys = [
  CusLabel(cnLabel: "中文", value: "chinese"),
  CusLabel(cnLabel: "英语", value: "english"),
  CusLabel(cnLabel: "日语", value: "japanese"),
  CusLabel(cnLabel: "阿拉伯语", value: "arabic"),
  CusLabel(cnLabel: "印度尼西亚语", value: "indonesian"),
  CusLabel(cnLabel: "吉尔吉斯语", value: "kyrgyz"),
  CusLabel(cnLabel: "波斯语", value: "persian"),
  CusLabel(cnLabel: "索马里语", value: "somali"),
  CusLabel(cnLabel: "土耳其语", value: "turkish"),
  CusLabel(cnLabel: "越南语", value: "vietnamese"),
  CusLabel(cnLabel: "阿塞拜疆语", value: "azeri"),
  CusLabel(cnLabel: "法语", value: "french"),
  CusLabel(cnLabel: "马拉地语", value: "marathi"),
  CusLabel(cnLabel: "葡萄牙语", value: "portuguese"),
  CusLabel(cnLabel: "西班牙语", value: "spanish"),
  CusLabel(cnLabel: "乌克兰语", value: "ukrainian"),
  CusLabel(cnLabel: "孟加拉语", value: "bengali"),
  CusLabel(cnLabel: "豪萨语", value: "hausa"),
  CusLabel(cnLabel: "基尼亚鲁瓦语", value: "kinyarwanda"),
  CusLabel(cnLabel: "尼泊尔语", value: "nepali"),
  CusLabel(cnLabel: "俄语", value: "russian"),
  CusLabel(cnLabel: "斯瓦希里语", value: "swahili"),
  CusLabel(cnLabel: "乌尔都语", value: "urdu"),
  CusLabel(cnLabel: "缅甸语", value: "burmese"),
  CusLabel(cnLabel: "印地语", value: "hindi"),
  CusLabel(cnLabel: "隆迪语", value: "kirundi"),
  CusLabel(cnLabel: "普什图语", value: "pashto"),
  CusLabel(cnLabel: "僧伽罗语", value: "sinhala"),
  CusLabel(cnLabel: "泰米尔语", value: "tamil"),
  CusLabel(cnLabel: "乌兹别克语", value: "uzbek"),
  CusLabel(cnLabel: "约鲁巴语", value: "yoruba"),
];

///
/// 头条新闻
/// https://github.com/Meowv/ToutiaoNews
/// 没有分页，只能看到一点点
///
class SutBbcNewsRespPage extends StatefulWidget {
  const SutBbcNewsRespPage({super.key});

  @override
  State<SutBbcNewsRespPage> createState() => _SutBbcNewsRespPageState();
}

class _SutBbcNewsRespPageState
    extends BaseNewsPageState<SutBbcNewsRespPage, SutBbcNews> {
  @override
  List<CusLabel> getCategories() => langCategorys;

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
      SutBbcNewsResp htRst = await newsApiManager.getSutBbcNewsList(
        // 基类命名分类，实际这里是语言分类
        lang: (selectedNewsCategory.value as String),
      );

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          // 把所有分类的新闻都放进来
          newsList = [];
          for (SutBbcNewsCategory category in htRst.categories ?? []) {
            // 用作分类的分割(手动添加的【【】】，需要在构建新闻卡片列表时特殊处理)
            var temp = SutBbcNews(
              title: "【【${category.categoryName}】】",
              newsLink: '',
              imageLink: '',
            );

            newsList.addAll([temp, ...category.items]);
          }
        } else {
          newsList.addAll(htRst.categories?.first.items ?? []);
        }

        // 这个API没看到分页参数，暂时就当作只有1页
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
  Widget buildNewsCard(SutBbcNews item, int index) {
    if (item.title != null &&
        item.title!.startsWith('【【') &&
        item.title!.endsWith('】】')) {
      // 用作分类的分割(手动添加的【【】】，需要在构建新闻卡片列表时特殊处理，只保留一个)
      return Container(
        padding: EdgeInsets.all(10),
        child: Text(
          item.title!.substring(1, item.title!.length - 1),
          style: TextStyle(
            fontSize: 16,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CoverNewsCard(
      title: item.title ?? '',
      summary: item.summary ?? '',
      url: item.newsLink ?? '',
      // 新闻图片无法加载，这里使用媒体头像
      imageUrl: item.imageLink ?? '',
      source: 'BBC News',
      author: '',
      // 源网页显示的是发布时间而不是修改时间
      publishedAt: '',
      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => 'BBC新闻';

  @override
  String getInfoMessage() =>
      """数据来源：Github [Sayad-Uddin-Tahsin/BBC-News-API](https://github.com/Sayad-Uddin-Tahsin/BBC-News-API)\n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
