import 'package:flutter/material.dart';
import '../../../common/utils/screen_helper.dart';

import 'components/api_key_config.dart';
import 'components/model_list.dart';

class BriefModelConfig extends StatefulWidget {
  const BriefModelConfig({super.key});

  @override
  State<BriefModelConfig> createState() => _BriefModelConfigState();
}

class _BriefModelConfigState extends State<BriefModelConfig>
    with SingleTickerProviderStateMixin {
  // 在桌面端使用自定义的TabController
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // 如果是桌面端，创建自定义TabController
    if (ScreenHelper.isDesktop()) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    // 释放资源
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 桌面端和移动端使用不同的布局
    if (ScreenHelper.isDesktop()) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // 桌面端布局 - 使用分割视图
  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型配置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Row(
        children: [
          // 左侧导航栏
          Card(
            margin: EdgeInsets.all(12),
            elevation: 4,
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildNavItem(0, '模型列表', Icons.list_alt),
                  _buildNavItem(1, 'API配置', Icons.key),
                ],
              ),
            ),
          ),

          // 右侧内容区
          Expanded(
            child: Card(
              margin: EdgeInsets.only(top: 12, right: 12, bottom: 12),
              elevation: 4,
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(), // 禁止左右滑动切换
                children: [ModelList(), ApiKeyConfig()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局 - 使用标签页
  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('模型配置'),
          bottom: const TabBar(tabs: [Tab(text: '模型列表'), Tab(text: 'API配置')]),
          elevation: 1,
        ),
        body: const TabBarView(children: [ModelList(), ApiKeyConfig()]),
      ),
    );
  }

  // 导航栏项
  Widget _buildNavItem(int index, String title, IconData icon) {
    final bool isSelected = _tabController?.index == index;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        if (_tabController != null) {
          _tabController!.animateTo(index);
          // 强制重建UI以更新选中状态
          setState(() {});
        }
      },
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 20),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color:
              isSelected
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
