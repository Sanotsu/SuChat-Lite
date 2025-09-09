import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../../shared/constants/constants.dart';
import '../../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/baike_history_in_today_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

class BaikeHistoryInTodayPage extends StatefulWidget {
  const BaikeHistoryInTodayPage({super.key});

  @override
  State<BaikeHistoryInTodayPage> createState() =>
      _BaikeHistoryInTodayPageState();
}

class _BaikeHistoryInTodayPageState
    extends BaseNewsPageState<BaikeHistoryInTodayPage, BaikeHihItem> {
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
      BaikeHistoryInTodayResp htRst = await newsApiManager
          .getBaikeHistoryInTodayList();

      if (!mounted) return;
      setState(() {
        // 反转一下，从近到远
        newsList = (htRst.items ?? []).reversed.toList();
        // 这个API没看到分页参数
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
  Widget buildNewsCard(BaikeHihItem item, int index) {
    var title = (item.title != null && item.year != null)
        ? "${item.year}年  ${item.title}"
        : (item.title ?? "");

    return CoverNewsCard(
      title: title,
      summary: item.description ?? '',
      url: item.link ?? '',
      source: '百度百科',
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '历史上的今天';

  @override
  Widget getAppBarTitleWidget() {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(
            text: "历史上的今天\t",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
          TextSpan(
            text: DateFormat(formatToYMDzh).format(DateTime.now()),
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  String getInfoMessage() =>
      """数据来源：Github [vikiboss/60s](https://github.com/vikiboss/60s)
      \n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
