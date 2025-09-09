import 'package:flutter/material.dart';

import '../../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../../core/utils/datetime_formatter.dart';
import '../../../../../../shared/constants/constants.dart';
import '../../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/uo_ithome_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

class UnofficialITHomePage extends StatefulWidget {
  const UnofficialITHomePage({super.key});

  @override
  State<UnofficialITHomePage> createState() => _UnofficialITHomePageState();
}

class _UnofficialITHomePageState
    extends BaseNewsPageState<UnofficialITHomePage, UoItHomeNews> {
  @override
  List<CusLabel> getCategories() => [];

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
      UoItHomeResp htRst = await newsApiManager.getUoItHomeList();

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          newsList = htRst.newslist ?? [];
        } else {
          newsList.addAll(htRst.newslist ?? []);
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
  Widget buildNewsCard(UoItHomeNews item, int index) {
    return CoverNewsCard(
      title: item.title ?? '',
      summary: item.description ?? '',
      url: "https://ithome.com/${item.url ?? ''}",
      // 新闻图片无法加载，这里使用媒体头像
      imageUrl: item.image ?? '',
      source: 'IT之家',
      author: '',
      // 源网页显示的是发布时间而不是修改时间
      publishedAt: formatTimestampToString(
        DateTime.parse(item.postdate ?? '').millisecondsSinceEpoch.toString(),
      ),
      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => 'IT之家';

  @override
  String getInfoMessage() =>
      """数据来源：Github [F-loat/ithome-lite](https://github.com/F-loat/ithome-lite)
      \n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
