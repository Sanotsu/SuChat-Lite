import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../core/utils/simple_tools.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/news_api_manager.dart';
import '../../../data/models/readhub_resp.dart';
import '../../widgets/cover_news_card.dart';
import '../base_news_page/base_news_page_state.dart';

List<CusLabel> readhubTypes = [
  // 热门话题和其他分类的url和返回内容不太一样，999是自定义的分类值
  CusLabel(cnLabel: "热门话题", value: 999),
  CusLabel(cnLabel: "科技动态", value: 1),
  CusLabel(cnLabel: "医疗产业", value: 6),
  CusLabel(cnLabel: "财经快讯", value: 7),
  CusLabel(cnLabel: "AI", value: 8),
  CusLabel(cnLabel: "汽车", value: 9),
  CusLabel(cnLabel: "[不清楚]", value: 0),
];

class ReadHubPage extends StatefulWidget {
  const ReadHubPage({super.key});

  @override
  State<ReadHubPage> createState() => _ReadHubPageState();
}

class _ReadHubPageState extends BaseNewsPageState<ReadHubPage, ReadhubItem> {
  // 获取分类
  @override
  List<CusLabel> getCategories() => readhubTypes;

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
      ReadhubResp rst = await newsApiManager.getReadhubList(
        page: currentPage,
        size: pageSize,
        type: (selectedNewsCategory.value as int),
      );

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          newsList = rst.items ?? [];
        } else {
          newsList.addAll(rst.items ?? []);
        }

        // 暂时设定一定有下一页吧，因为没有看到总数说明
        hasMore = true;

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
  Widget buildNewsCard(ReadhubItem item, int index) {
    return selectedNewsCategory.cnLabel == "热门话题"
        ? buildHotTopicCard(item, index)
        : CoverNewsCard(
            title: item.title,
            summary: item.summary,
            url: item.url ?? '',
            author: item.siteNameDisplay,
            source: item.siteNameDisplay ?? "",
            publishedAt: formatTimeAgo(item.publishDate ?? ''),
            index: index,
            isExpandedList: isExpandedList,
          );
  }

  @override
  String getAppBarTitle() => 'ReadHub';

  @override
  String getInfoMessage() => """数据来源：[ReadHub](https://readhub.cn/)
\n请勿频繁请求，避免IP封禁、影响原网站运行。""";

  @override
  bool get showSearchBox => false;

  @override
  int get pageSize => 20;

  /// 热点话题新闻卡片
  Widget buildHotTopicCard(ReadhubItem item, int index) {
    // 记录当前新闻是否被点开
    bool isExpanded = isExpandedList[index];

    // 卡片在展开时和未展开时背景、边框、阴影等都稍微有点区别
    return Card(
      elevation: isExpanded ? 5 : 0,
      color: isExpanded ? null : Theme.of(context).canvasColor,
      shape: isExpanded
          ? null
          : RoundedRectangleBorder(
              // 未展开时取消圆角
              borderRadius: BorderRadius.zero,
            ),
      child: ExpansionTile(
        showTrailingIcon: false,
        initiallyExpanded: isExpanded,
        // 折叠栏展开后不显示上下边框线
        shape: const Border(),
        childrenPadding: EdgeInsets.all(5),
        onExpansionChanged: (expanded) {
          setState(() {
            isExpandedList[index] = expanded;
          });
        },
        // 减少标题和子标题的 padding
        tilePadding: EdgeInsets.all(5),
        // 减少展开后的内容区域的 padding
        // childrenPadding: EdgeInsets.all(0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    // "${index + 1} ${item.title}",
                    item.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.end,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${item.siteNameDisplay}\t\t\t\t",
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    TextSpan(
                      text: formatTimeAgo(item.publishDate ?? ''),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          item.summary,
          maxLines: isExpanded ? null : 3,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(
            color: isExpanded ? null : Colors.black54,
            fontSize: 14,
          ),
          // 新闻总结文字两端对齐
          textAlign: TextAlign.justify,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.newsAggList != null && item.newsAggList!.isNotEmpty) ...[
            Text(
              "新闻报道",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.start,
            ),
            ...(item.newsAggList!).map((newsAgg) => buildNewsAggItem(newsAgg)),
          ],
          if (item.timeline?.topics != null &&
              item.timeline!.topics!.isNotEmpty) ...[
            Divider(),
            Text(
              "相关话题",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.start,
            ),
            ...(item.timeline!.topics!).map(
              (detail) => buildTimelineItem(detail),
            ),
          ],
        ],
      ),
    );
  }

  // 关联新闻
  Column buildNewsAggItem(ReadhubNewsAggList newsAgg) {
    return Column(
      children: [
        Divider(),
        GestureDetector(
          onTap: () => launchStringUrl(newsAgg.url ?? ""),
          child: Row(
            children: [
              // Icon(Icons.link, size: 20, color: Colors.grey),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  newsAgg.title ?? '',
                  style: TextStyle(color: Colors.blue, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              VerticalDivider(width: 5, thickness: 2, color: Colors.red),
              Container(
                width: 70,
                padding: EdgeInsets.only(right: 5),
                child: Text(
                  newsAgg.siteNameDisplay ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 相关话题时间线
  ListTile buildTimelineItem(ReadhubTimelineTopic topic) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: 5, right: 5),
      // 年月日的时间字符串
      leading: SizedBox(
        width: 65,
        child: Text(
          DateFormat(formatToYMD).format(DateTime.parse(topic.createdAt ?? '')),
          style: TextStyle(color: Colors.grey),
        ),
      ),
      // 新闻标题
      title: Text(
        topic.title ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          decoration: TextDecoration.underline, // 添加下划线
          decorationColor: Colors.blue, // 下划线颜色
          decorationThickness: 2, // 下划线粗细
        ),
      ),
      onTap: () => launchStringUrl("https://readhub.cn/topic/${topic.uid}"),
    );
  }
}
