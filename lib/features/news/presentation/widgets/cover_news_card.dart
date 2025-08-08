import 'package:flutter/material.dart';

import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/image_preview_helper.dart';

// 除了readhub热门话题那个有关联新闻、有时间线
// 其他的新闻预览卡片基本都可以使用这个可折叠栏卡片组件
// 布局基本为：标题、概要、图片?、作者?、来源、地址跳转

class CoverNewsCard extends StatefulWidget {
  // 标题
  final String title;
  // 简述
  final String summary;
  // 标题图片
  final String? imageUrl;
  // 来源媒体
  final String source;
  // 虽然是作者栏位，但也可以是关键字、tag等其他内容
  final String? author;
  // 发表时间
  final String? publishedAt;
  // 新闻源链接
  final String url;
  // 包含折叠状态的列表
  final List<bool> isExpandedList;
  // 当前属于哪一个，用于获取当前新闻卡片的折叠状态
  final int index;

  const CoverNewsCard({
    super.key,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.source,
    this.author,
    this.publishedAt,
    required this.url,
    required this.index,
    required this.isExpandedList,
  });

  @override
  State<CoverNewsCard> createState() => _CoverNewsCardState();
}

class _CoverNewsCardState extends State<CoverNewsCard> {
  bool get isExpanded => widget.isExpandedList[widget.index];

  void _onExpansionChanged(bool expanded) {
    setState(() {
      widget.isExpandedList[widget.index] = expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isExpanded ? 5 : 0,
      color: isExpanded ? null : Theme.of(context).canvasColor,
      shape: isExpanded
          ? null
          : RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ExpansionTile(
        showTrailingIcon: false,
        initiallyExpanded: isExpanded,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        onExpansionChanged: _onExpansionChanged,
        tilePadding: EdgeInsets.all(5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  Container(
                    width: 100,
                    padding: EdgeInsets.only(left: 5),
                    height: 70,
                    child: buildNetworkOrFileImage(
                      widget.imageUrl!,
                      fit: BoxFit.scaleDown,
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
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.publishedAt ?? "",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    // 虽然是作者栏位，但也可以是关键字、tag等其他内容
                    TextSpan(
                      text: "\t\t\t\t${widget.author ?? ''}",
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        subtitle: widget.summary.isEmpty
            ? null
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.summary,
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isExpanded ? null : Colors.black54,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
        children: [
          ListTile(
            title: Text(
              '来源: ${widget.source}',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
                decorationThickness: 2,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () => launchStringUrl(widget.url),
          ),
        ],
      ),
    );
  }
}
