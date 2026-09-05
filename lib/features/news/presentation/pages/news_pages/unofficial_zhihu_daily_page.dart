import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/uo_zhihu_daily_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

class UnofficialZhihuDailyPage extends StatefulWidget {
  const UnofficialZhihuDailyPage({super.key});

  @override
  State<UnofficialZhihuDailyPage> createState() =>
      _UnofficialZhihuDailyPageState();
}

class _UnofficialZhihuDailyPageState
    extends BaseNewsPageState<UnofficialZhihuDailyPage, UoZDSItem> {
  // 获取分类
  @override
  List<CusLabel> getCategories() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd');
    final dates = <CusLabel>[
      CusLabel(cnLabel: "最新", value: "latest", enLabel: "latest"),
    ];

    // 从今天往前推14天（共14天，不包括今天）
    for (int i = 1; i < 15; i++) {
      final date = now.subtract(Duration(days: i));
      dates.add(
        CusLabel(
          cnLabel: formatter.format(date),
          // 注意：选择了日期会调用before接口
          // 而如果before/20250812，其实是查询20250811的数据
          // 所以查询使用的alue要+1,才能和显示的日期是同一天
          value: formatter.format(date.add(const Duration(days: 1))),
          enLabel: formatter.format(date),
        ),
      );
    }

    return dates;
  }

  // 获取新闻数据
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
      UoZhihuDailyResp rst = await newsApiManager.getUoZhihuDailyList(
        date: selectedNewsCategory.value as String,
      );

      if (!mounted) return;
      setState(() {
        var temp = (rst.stories ?? []) + (rst.topStories ?? []);
        // 过滤掉temp中id重复的数据
        final uniqueMap = <String, UoZDSItem>{};
        for (var item in temp) {
          uniqueMap.putIfAbsent(item.id.toString(), () => item);
        }
        temp = uniqueMap.values.toList();

        if (currentPage == 1) {
          newsList = temp;
        } else {
          newsList.addAll(temp);
        }

        hasMore = false;

        // 重新加载新闻列表都是未加载的状态
        isExpandedList = List.generate(newsList.length, (index) => false);
      });
    } on CusHttpException catch (e) {
      // API请求报错，显示报错信息
      // http连接相关的报错在拦截器就有弹窗报错了，这里暂时不显示了
      debugPrint(e.toString());
    } catch (e) {
      // 其他错误，可能有转型报错啥的，所以还是显示一下
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
  Widget buildNewsCard(UoZDSItem item, int index) {
    return CoverNewsCard(
      title: item.title ?? '',
      summary: '',
      url: item.url ?? '',
      imageUrl: (item.images != null && item.images!.isNotEmpty)
          ? item.images?.first
          : (item.image ?? ''),
      author: item.hint,
      source: "知乎日报",
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '知乎日报';

  @override
  String getInfoMessage() =>
      """数据来源：[https://apis.netstart.cn/zhihudaily](https://apis.netstart.cn/zhihudaily)
\n和官方的知乎日报数据相比有缺失""";

  @override
  bool get showSearchBox => false;
}
