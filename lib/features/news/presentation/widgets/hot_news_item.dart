import 'package:flutter/material.dart';

import '../../../../core/utils/simple_tools.dart';

/// 有简介、有封面图的新闻用 CoverNewsCard ，只有标题等热榜新闻，就用这个
class HotNewsItem extends StatelessWidget {
  final int index;
  final String title;
  final String? trailingText;
  final String link;

  const HotNewsItem({
    super.key,
    required this.index,
    required this.title,
    this.trailingText,
    required this.link,
  });

  void _launchUrl(String url) async {
    if (!url.startsWith("http") && !url.startsWith("https")) {
      url = "https:$url";
    }
    launchStringUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => _launchUrl(link),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    "$index",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                if (trailingText != null && trailingText!.isNotEmpty)
                  SizedBox(
                    width: 48,
                    child: Text(
                      trailingText!,
                      style: TextStyle(fontSize: 11),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(width: 10),
              ],
            ),
          ),
        ),
        Divider(height: 1),
      ],
    );
  }
}

/// 就是上面组件的函数形式
/// 自定义的比直接使用ListTile更紧凑点，其他没区别
Widget buildNewsItemContainer(
  BuildContext context,
  int index,
  String title, {
  String? trailingText,
  void Function()? onTap,
}) {
  return Column(
    children: [
      InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  "$index",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (trailingText != null && trailingText.isNotEmpty)
                SizedBox(
                  width: 48,
                  child: Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 11,
                      // color: Theme.of(context).disabledColor,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(width: 10),
            ],
          ),
        ),
      ),
      Divider(height: 1),
    ],
  );
}
