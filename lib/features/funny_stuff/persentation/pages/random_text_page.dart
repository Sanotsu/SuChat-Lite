import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../core/network/url_utils.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/datasources/index.dart';

class RandomTextPage extends StatefulWidget {
  const RandomTextPage({super.key});

  @override
  State<RandomTextPage> createState() => _RandomTextPageState();
}

class _RandomTextPageState extends State<RandomTextPage> {
  String _textUrl = '';

  // 保存文本和URL
  final List<Map<String, String>> _textRecords = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  final ScrollController _textScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRandomText();
  }

  @override
  void dispose() {
    _textScrollController.dispose();
    super.dispose();
  }

  String getTextUrl() {
    var orignalUrl = textUrlList[Random().nextInt(textUrlList.length)];
    var time = DateTime.now().millisecondsSinceEpoch;

    return orignalUrl.contains("?")
        ? "$orignalUrl&t=$time"
        : "$orignalUrl?t=$time";
  }

  Future<void> _fetchRandomText() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    bool isAvailable = await UrlUtils.isUrlAvailable('https://api.suyanw.cn');

    if (!isAvailable) {
      ToastUtils.showError('站点不可用，请稍后再试');

      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _textUrl = getTextUrl();
    });

    try {
      final response = await HttpUtils.get(
        path: _textUrl,
        responseType: CusRespType.plain,
        headers: {'Accept': 'text/plain'},
        showLoading: true,
        showErrorMessage: false,
      );

      final newText = response.toString().trim();

      if (!mounted) return;
      setState(() {
        _textRecords.add({'text': newText, 'url': _textUrl});
        _currentIndex = _textRecords.length - 1;
        _isLoading = false;
      });

      // 滚动到顶部确保长文本从头显示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // print('获取文本失败: ${e.toString()}');
      // print(_textUrl);

      ToastUtils.showError('获取文本失败: ${e.toString()}');
    }
  }

  void _showPreviousText() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _scrollToTop();
    }
  }

  void _showNextText() {
    if (_currentIndex < _textRecords.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _scrollToTop();
    } else {
      // 如果没有下一句，则获取新文本
      _fetchRandomText();
    }
  }

  void _scrollToTop() {
    _textScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('随机语录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRandomText,
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'prev',
            onPressed: _showPreviousText,
            child: const Icon(Icons.arrow_upward),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'next',
            onPressed: _showNextText,
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _textRecords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textRecords.isEmpty) {
      return const Center(child: Text('暂无文本，请点击刷新'));
    }

    final currentRecord = _textRecords[_currentIndex];
    final fullText = currentRecord['text']!;
    final textArr = fullText.split("——");
    final text = textArr.first;
    final author = textArr.length > 1 ? "——${textArr.last}" : "";
    final url = currentRecord['url']!.split("?").first;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _showPreviousText();
        } else if (details.primaryVelocity! < 0) {
          _showNextText();
        }
      },
      child: Column(
        children: [
          // 显示URL地址
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    url,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          // 显示复制文案按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      _textRecords.isEmpty
                          ? '0/0'
                          : '${_currentIndex + 1}/${_textRecords.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: '复制文案',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fullText));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('文案已复制')));
                  },
                ),
              ],
            ),
          ),
          // 显示文本内容
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                controller: _textScrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // 文案显示的区域:屏幕高度 减去 状态栏、appbar、url区域、复制按钮区域、边框等
                    minHeight: MediaQuery.of(context).size.height - 350,
                  ),
                  child: Container(
                    color: Colors.green.withValues(alpha: 0.2),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: Column(
                        key: ValueKey<String>(fullText),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          if (author.isNotEmpty)
                            Text(
                              author,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.end,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
