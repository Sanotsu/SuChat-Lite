import 'package:flutter/material.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/jiqizhixin_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

class JiqizhixinPage extends StatefulWidget {
  const JiqizhixinPage({super.key});

  @override
  State<JiqizhixinPage> createState() => _JiqizhixinPageState();
}

class _JiqizhixinPageState
    extends BaseNewsPageState<JiqizhixinPage, JiqizhixinArticle> {
  // 获取分类
  @override
  List<CusLabel> getCategories() => [];

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
      JiqizhixinResp rst = await newsApiManager.getJiqizhixinList(
        page: currentPage,
        size: pageSize,
      );

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          newsList = rst.articles ?? [];
        } else {
          newsList.addAll(rst.articles ?? []);
        }

        hasMore = rst.hasNextPage ?? false;

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
  Widget buildNewsCard(JiqizhixinArticle item, int index) {
    return CoverNewsCard(
      title: item.title ?? '',
      summary: item.content ?? '',
      // https://www.jiqizhixin.com/articles/2025-08-05-5
      url: "https://www.jiqizhixin.com/articles/${item.slug}",
      imageUrl: item.coverImageUrl ?? '',
      author: item.author,
      source: item.source ?? "",
      publishedAt: item.publishedAt ?? '',
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '机器之心';

  @override
  String getInfoMessage() => """数据来源：[机器之心](https://www.jiqizhixin.com/)
\n请勿频繁请求，避免IP封禁、影响原网站运行。""";

  @override
  bool get showSearchBox => false;
}
