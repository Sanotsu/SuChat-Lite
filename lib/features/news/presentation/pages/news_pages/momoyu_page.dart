import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/momoyu_resp.dart';
import '../../widgets/hot_news_item.dart';
import '../base_news_page/base_news_page_state.dart';

List<CusLabel> momoyuItems = [
  // 新闻资讯
  CusLabel(cnLabel: "今日头条", value: 69),
  CusLabel(cnLabel: "虎嗅", value: 38),
  // 热门社区
  CusLabel(cnLabel: "微博热搜", value: 3),
  CusLabel(cnLabel: "知乎热榜", value: 1),
  CusLabel(cnLabel: "虎扑步行街", value: 47),
  CusLabel(cnLabel: "豆瓣热话", value: 2),
  // 视频平台
  CusLabel(cnLabel: "B站", value: 18),
  // 购物平台
  CusLabel(cnLabel: "值得买3小时热门", value: 28),
  // IT科技
  CusLabel(cnLabel: "IT之家", value: 6),
  CusLabel(cnLabel: "中关村在线", value: 7),
  CusLabel(cnLabel: "爱范儿", value: 9),
  // 程序员聚集地
  CusLabel(cnLabel: "开源中国", value: 12),
  CusLabel(cnLabel: "CSDN", value: 46),
  CusLabel(cnLabel: "掘金", value: 52),
];

class MomoyuPage extends StatefulWidget {
  const MomoyuPage({super.key});

  @override
  State<MomoyuPage> createState() => _MomoyuPageState();
}

class _MomoyuPageState extends BaseNewsPageState<MomoyuPage, MMYDataItem> {
  String onlineCount = '无数据';
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    fetchUserCount();

    // 启动定时器，每 60 秒查询一次数据
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchUserCount();
    });
  }

  @override
  void dispose() {
    // 取消定时器，防止内存泄漏
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchUserCount() async {
    try {
      final rst = await newsApiManager.getMomoyuUserCount();
      if (!mounted) return;
      setState(() {
        onlineCount = "实时摸鱼 ${rst.data ?? 0} 人";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          onlineCount = '查询摸鱼人数失败';
        });
      }
    }
  }

  @override
  List<CusLabel> getCategories() => momoyuItems;

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
      fetchUserCount();

      MomoyuResp<MMYIdData> htRst = await newsApiManager.getMomoyuList(
        id: (selectedNewsCategory.value as int),
      );

      if (!mounted) return;
      setState(() {
        newsList = htRst.data?.list ?? [];
        lastTime = htRst.data?.time;
        // 摸摸鱼是热榜，没有分页
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
  Widget buildNewsCard(MMYDataItem item, int index) {
    // 有预览图和概要的就用CusNewsCard，只有标题和url的就用这个
    return HotNewsItem(
      index: index + 1,
      title: item.title ?? "",
      trailingText: item.extra,
      link: item.link ?? "https://momoyu.cc/",
    );
  }

  @override
  String getAppBarTitle() => '摸摸鱼';

  @override
  Widget getAppBarTitleWidget() {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(
            text: "摸摸鱼\t",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
          TextSpan(
            text: onlineCount,
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  String getInfoMessage() =>
      """数据来源：[摸摸鱼](https://momoyu.cc/)\n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
