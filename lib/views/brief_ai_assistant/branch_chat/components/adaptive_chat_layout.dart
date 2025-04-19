import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/utils/screen_helper.dart';

/// 自适应聊天布局组件
/// 在移动端显示正常的Scaffold，在桌面端显示带有侧边栏的布局
class AdaptiveChatLayout extends StatelessWidget {
  /// 主要内容
  final Widget body;

  /// 历史记录内容(在移动端作为抽屉，在桌面端作为侧边栏)
  final Widget historyContent;

  final Widget? rightSidebar;

  /// 应用栏
  final PreferredSizeWidget? appBar;

  /// 应用栏标题
  final Widget? title;

  /// 应用栏操作按钮
  final List<Widget>? actions;

  /// 是否显示历史记录侧边栏(仅桌面端有效)
  final bool isHistorySidebarVisible;

  /// 历史记录侧边栏切换回调
  final Function(bool) onHistorySidebarToggled;

  /// 是否正在加载
  final bool isLoading;

  /// 背景部件
  final Widget? background;

  /// 浮动头像按钮
  final Widget? floatingAvatarButton;

  /// 构造函数
  const AdaptiveChatLayout({
    super.key,
    required this.body,
    required this.historyContent,
    this.rightSidebar,
    this.appBar,
    this.title,
    this.actions,
    required this.isHistorySidebarVisible,
    required this.onHistorySidebarToggled,
    this.isLoading = false,
    this.background,
    this.floatingAvatarButton,
  });

  @override
  Widget build(BuildContext context) {
    // 如果是加载中状态，显示加载指示器
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 判断是否为桌面平台
    final isDesktop = ScreenHelper.isDesktop();

    // 桌面平台使用侧边栏布局
    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    // 移动平台使用抽屉布局
    else {
      return _buildMobileLayout(context);
    }
  }

  /// 构建桌面平台布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // 背景
          if (background != null) background!,

          // 主体内容
          Row(
            children: [
              // 历史记录侧边栏
              if (isHistorySidebarVisible)
                SizedBox(
                  width: 280, // 侧边栏固定宽度
                  child: Material(elevation: 2, child: historyContent),
                ),

              // 主内容区域
              Expanded(
                child: Scaffold(
                  appBar: _buildDesktopAppBar(context),
                  body: body,
                  backgroundColor: Colors.transparent,
                ),
              ),

              // 右侧侧边栏
              if (rightSidebar != null) rightSidebar!,
            ],
          ),

          // 浮动按钮
          if (floatingAvatarButton != null) floatingAvatarButton!,
        ],
      ),
    );
  }

  /// 构建移动平台布局
  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // 背景
          if (background != null) background!,

          // 主体内容
          Scaffold(
            appBar: appBar,
            drawer: Drawer(width: 0.8.sw, child: historyContent),
            onDrawerChanged: (isOpen) {
              onHistorySidebarToggled(isOpen);
            },
            body: body,
            backgroundColor: Colors.transparent,
          ),

          // 浮动按钮
          if (floatingAvatarButton != null) floatingAvatarButton!,
        ],
      ),
    );
  }

  /// 构建桌面平台的应用栏
  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(isHistorySidebarVisible ? Icons.menu_open : Icons.menu),
        onPressed: () => onHistorySidebarToggled(!isHistorySidebarVisible),
      ),
      title: title,
      actions: actions,
    );
  }
}
