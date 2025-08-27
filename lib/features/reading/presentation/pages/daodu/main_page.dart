import 'package:flutter/material.dart';

import 'daily_card_page.dart';
import 'explore_page.dart';

/// 岛读主页面 - 包含底部导航的主容器
class DaoduMainPage extends StatefulWidget {
  const DaoduMainPage({super.key});

  @override
  State<DaoduMainPage> createState() => _DaoduMainPageState();
}

class _DaoduMainPageState extends State<DaoduMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const DailyCardPage(), const ExplorePage()];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: '阅读',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: '探索',
          ),
        ],
      ),
    );
  }
}
