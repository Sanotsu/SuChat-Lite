import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 简单展示 WebView 页面，传入 url 即可
class FullWebPage extends StatefulWidget {
  final String url;
  final String? title;

  const FullWebPage({super.key, required this.url, this.title});

  @override
  State<FullWebPage> createState() => _FullWebPageState();
}

class _FullWebPageState extends State<FullWebPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? "网页浏览")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
