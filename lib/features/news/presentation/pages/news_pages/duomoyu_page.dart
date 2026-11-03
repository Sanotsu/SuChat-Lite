import 'package:flutter/material.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/duomoyu_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

/// 多摸鱼热榜页
/// 2026-09-04 API 改版重构：
/// - 分类(新闻源)由 /api/news/sources 动态下发，不再本地写死
/// - 热榜走 /api/news/rankings/{slug}，条目为 rank/title/url/hotValue/publishedAt
class DuomoyuPage extends StatefulWidget {
  const DuomoyuPage({super.key});

  @override
  State<DuomoyuPage> createState() => _DuomoyuPageState();
}

class _DuomoyuPageState extends BaseNewsPageState<DuomoyuPage, DuomoyuItem> {
  // 动态分类列表(从接口加载，替代历史硬编码清单)
  final List<CusLabel> _categoryList = [];

  @override
  List<CusLabel> getCategories() => _categoryList;

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
      // 首次进入(分类未加载)先拉新闻源列表
      if (_categoryList.isEmpty) {
        await _loadCategories();
        if (!mounted) return;
        if (_categoryList.isEmpty) return;
      }

      DuomoyuRankingResp htRst = await newsApiManager.getDuomoyuRanking(
        slug: (selectedNewsCategory.value as String),
      );

      if (!mounted) return;
      setState(() {
        newsList = htRst.data?.items ?? [];
        lastTime = htRst.data?.source?.updatedAt;
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

  /// 加载新闻源作为动态分类
  Future<void> _loadCategories() async {
    try {
      final sources = await newsApiManager.getDuomoyuSources();
      // 仅保留公开可查且数据未过期的源(接口已按 displayOrder 排序)
      final usable = sources.where((s) => s.isUsable).toList();

      if (usable.isEmpty) {
        ToastUtils.showError('暂无可用新闻源，请稍后重试');
        return;
      }

      setState(() {
        _categoryList
          ..clear()
          ..addAll(
            usable.map(
              (s) => CusLabel(cnLabel: s.label ?? s.slug ?? '', value: s.slug),
            ),
          );
        // 基类初始化时分类为空会填占位"全部/all"，这里对齐为第一个真实分类
        selectedNewsCategory = _categoryList[0];
      });
    } on CusHttpException catch (e) {
      // http连接相关的报错在拦截器就有弹窗报错了
      debugPrint(e.toString());
      ToastUtils.showError('新闻源加载失败，请下拉重试');
    } catch (e) {
      ToastUtils.showError(e.toString());
    }
  }

  @override
  Widget buildNewsCard(DuomoyuItem item, int index) {
    return CoverNewsCard(
      // 热榜带排名前缀
      title: '${item.rank}. ${item.title ?? ''}',
      // 新接口条目无摘要
      summary: '',
      url: item.url ?? '',
      // 新接口条目无封面图
      imageUrl: null,
      source: selectedNewsCategory.cnLabel,
      author: item.hotDisplay,
      // 新接口发布时间为 ISO8601 字符串(常为 null)
      publishedAt: formatDateTimeString(item.publishedAt),
      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '多摸鱼';

  @override
  String getInfoMessage() =>
      """数据来源：[多摸鱼](https://duomoyu.com/)\n\n新闻源由接口动态下发，不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
