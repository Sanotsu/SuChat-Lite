import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../common/utils/screen_provider.dart';

/// 响应式布局示例
/// 展示如何使用ScreenHelper和ScreenProvider实现响应式布局
class ResponsiveLayoutExample extends StatelessWidget {
  const ResponsiveLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用ScreenProvider构建适合当前屏幕大小的布局
    return Scaffold(
      appBar: AppBar(title: const Text('角色列表')),
      body: ScreenProvider.buildResponsive(
        context: context,
        // 移动端布局
        mobile: _buildMobileLayout(context),
        // 平板布局
        tablet: _buildTabletLayout(context),
        // 桌面布局
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  /// 构建移动端布局
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: ScreenProvider.getContentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '移动端布局',
              style: TextStyle(
                fontSize: ScreenHelper.getFontSize(20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ScreenHelper.isDesktop() ? 16.0 : 16.sp),
            _buildContentCard(context, isVertical: true),
          ],
        ),
      ),
    );
  }

  /// 构建平板端布局
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: ScreenProvider.getContentPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '平板端布局',
              style: TextStyle(
                fontSize: ScreenHelper.getFontSize(24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ScreenHelper.isDesktop() ? 20.0 : 20.sp),
            _buildContentCard(context, isVertical: false),
          ],
        ),
      ),
    );
  }

  /// 构建桌面端布局
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ScreenProvider.getContentMaxWidth(context),
          ),
          child: Padding(
            padding: ScreenProvider.getContentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '桌面端布局',
                  style: TextStyle(
                    fontSize: ScreenHelper.getFontSize(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ScreenHelper.isDesktop() ? 24.0 : 24.sp),
                _buildContentCard(context, isVertical: false),
                SizedBox(height: ScreenHelper.isDesktop() ? 24.0 : 24.sp),
                _buildExtraDesktopContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建内容卡片
  Widget _buildContentCard(BuildContext context, {required bool isVertical}) {
    // 根据方向构建不同的布局
    if (isVertical) {
      // 垂直布局
      return Column(
        children: [
          _buildImageSection(context),
          SizedBox(height: ScreenHelper.isDesktop() ? 16.0 : 16.sp),
          _buildTextSection(context),
        ],
      );
    } else {
      // 水平布局
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildImageSection(context)),
          SizedBox(width: ScreenHelper.isDesktop() ? 24.0 : 24.sp),
          Expanded(flex: 3, child: _buildTextSection(context)),
        ],
      );
    }
  }

  /// 构建图片部分
  Widget _buildImageSection(BuildContext context) {
    return Container(
      height: ScreenHelper.adaptHeight(200),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(
          ScreenHelper.isDesktop() ? 8.0 : 8.sp,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: ScreenHelper.adaptSp(64),
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// 构建文本部分
  Widget _buildTextSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '响应式标题',
          style: TextStyle(
            fontSize: ScreenHelper.getFontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ScreenHelper.isDesktop() ? 12.0 : 12.sp),
        Text(
          '这是一段演示文本，用于展示在不同设备上的响应式布局效果。'
          '通过使用ScreenHelper和ScreenProvider类，'
          '我们可以轻松实现在移动设备和桌面平台上都有良好表现的UI。',
          style: TextStyle(fontSize: ScreenHelper.getFontSize(14), height: 1.5),
        ),
        SizedBox(height: ScreenHelper.isDesktop() ? 16.0 : 16.sp),
        _buildButton(context),
      ],
    );
  }

  /// 构建按钮
  Widget _buildButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenHelper.isDesktop() ? 20.0 : 20.sp,
          vertical: ScreenHelper.isDesktop() ? 12.0 : 12.sp,
        ),
        textStyle: TextStyle(fontSize: ScreenHelper.getFontSize(14)),
      ),
      child: const Text('了解更多'),
    );
  }

  /// 构建桌面端额外内容
  Widget _buildExtraDesktopContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '桌面专属内容',
          style: TextStyle(
            fontSize: ScreenHelper.getFontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ScreenHelper.isDesktop() ? 16.0 : 16.sp),
        Container(
          padding: EdgeInsets.all(ScreenHelper.isDesktop() ? 24.0 : 24.sp),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(
              ScreenHelper.isDesktop() ? 8.0 : 8.sp,
            ),
          ),
          child: Column(
            children: [
              Text(
                '这部分内容只在桌面端显示，充分利用了桌面平台更大的屏幕空间。',
                style: TextStyle(
                  fontSize: ScreenHelper.getFontSize(14),
                  height: 1.5,
                ),
              ),
              SizedBox(height: ScreenHelper.isDesktop() ? 16.0 : 16.sp),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ScreenHelper.isDesktop() ? 8.0 : 8.sp,
                      ),
                      child: Container(
                        height: ScreenHelper.adaptHeight(120),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(
                            alpha: 0.1 * (index + 1),
                          ),
                          borderRadius: BorderRadius.circular(
                            ScreenHelper.isDesktop() ? 8.0 : 8.sp,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '项目 ${index + 1}',
                            style: TextStyle(
                              fontSize: ScreenHelper.getFontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
