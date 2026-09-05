import 'package:flutter/material.dart';
import '../shared/widgets/cus_content_width.dart';

import '../core/utils/screen_helper.dart';
import '../shared/widgets/feature_grid_card.dart';
import 'translator/presentation/pages/mini_translator_page.dart';
import 'visual_media/presentation/pages/index.dart';
import 'voice_recognition/presentation/index.dart';
import 'diet_diary/presentation/index.dart';
import 'food/presentation/pages/usda_food_data/index.dart';
import 'news/presentation/pages/index.dart';
import 'notebook/presentation/pages/notebook_page.dart';
import 'simple_accounting/presentation/pages/bill_list_page.dart';
import 'training_assistant/presentation/index.dart';
import 'visual_media/presentation/pages/tmdb/home_page.dart';
import 'reading/presentation/pages/daodu/main_page.dart';
import 'reading/presentation/pages/one/main_page.dart';

class AIToolPage extends StatefulWidget {
  const AIToolPage({super.key});

  @override
  State createState() => _AIToolPageState();
}

class _AIToolPageState extends State<AIToolPage> {
  /// 2026-09-04 入口页统一整理：三个板块(功能列表/扩展功能/生活娱乐)共用
  /// 同一section结构与卡片规格——标题行+Wrap居中(spacing 16)，卡片桌面150/移动80
  double get _cardSize => ScreenHelper.isDesktop() ? 150 : 80;

  @override
  Widget build(BuildContext context) {
    return CusContentWidth(
      maxWidth: 1000,
      child: Scaffold(
        // 2026-09-03 旧"模型配置"入口移除：模型/AK配置统一到聊天页-平台管理
        // (扩展功能的内置免费模型链路不依赖该页，仍正常可用)
        appBar: AppBar(title: const Text('更多功能')),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 顶部横幅
              topBanner(),

              // 免责声明
              disclaimer(),

              // 功能列表
              _buildSection("功能列表", [
                // 2026-09-03 媒体生成功能并入聊天模块(选定生成类模型即对应模式)，
                // 语音合成/图片生成/视频生成独立页入口移除，统一由 Chat 进入；
                // 录音文件识别(voice_recognition)为独立完整功能，保留入口
                _buildGridCard(
                  targetPage: const MiniTranslatorPage(),
                  title: "快速翻译",
                  icon: Icons.translate,
                  accentColor: Colors.purple,
                  isNew: false,
                ),
                _buildGridCard(
                  targetPage: const VoiceRecognitionPage(),
                  title: "语音识别",
                  icon: Icons.graphic_eq,
                  accentColor: Colors.teal,
                ),
              ]),

              // 扩展功能
              _buildSection("扩展功能", [
                _buildGridCard(
                  targetPage: const TrainingAssistantPage(),
                  title: "训练助手",
                  icon: Icons.fitness_center,
                  accentColor: Colors.indigo,
                ),
                _buildGridCard(
                  targetPage: const DietDiaryPage(),
                  title: "饮食日记",
                  icon: Icons.restaurant,
                  accentColor: Colors.indigo,
                ),
                _buildGridCard(
                  targetPage: const BillListPage(),
                  title: "极简记账",
                  icon: Icons.money,
                  accentColor: Colors.indigo,
                ),
                _buildGridCard(
                  targetPage: const NotebookPage(),
                  title: "记事本",
                  icon: Icons.note_alt,
                  accentColor: Colors.indigo,
                ),
              ]),

              // 注意事项
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: const Center(
                    child: Text(
                      "注意：以下功能模块均基于 API 实现，"
                      "随时可能停止服务或不可访问，"
                      "仅供学习交流，切不可他用。",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // 生活娱乐
              // (2025-10-21 豆果美食发现菜单详情API签名验证失败，入口已移除)
              _buildSection("生活娱乐", [
                _buildGridCard(
                  targetPage: const NewsIndex(),
                  title: "新闻热榜",
                  icon: Icons.newspaper,
                  accentColor: Colors.orange,
                ),
                _buildGridCard(
                  targetPage: const VisualMediaIndex(),
                  title: "动漫资讯",
                  icon: Icons.collections_bookmark,
                  accentColor: Colors.orange,
                ),
                _buildGridCard(
                  targetPage: const TmdbHomePage(),
                  title: "TMDB",
                  icon: Icons.movie,
                  accentColor: Colors.orange,
                ),
                _buildGridCard(
                  targetPage: const USDAFoodDataCentral(),
                  title: "USDA FDC",
                  icon: Icons.calculate,
                  accentColor: Colors.orange,
                ),
                _buildGridCard(
                  targetPage: const DaoduMainPage(),
                  title: "岛读",
                  icon: Icons.article,
                  accentColor: Colors.teal,
                ),
                _buildGridCard(
                  targetPage: const OneMainPage(),
                  title: "ONE阅读",
                  icon: Icons.book_outlined,
                  accentColor: Colors.teal,
                ),
              ]),

              // 底部间距
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter topBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "SuChat",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "让创意与效率并存，探索AI的无限可能",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter disclaimer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "所有由人工智能模型生成的内容，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度和观点",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 统一的板块结构：竖条标题 + 卡片Wrap居中
  SliverToBoxAdapter _buildSection(String title, List<Widget> cards) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 2026-09-04 换行后的尾行也从左依次排(居中会导致尾行孤立居中难看)
            Wrap(
              alignment: WrapAlignment.start,
              spacing: ScreenHelper.isDesktop() ? 8 : 0,
              runSpacing: ScreenHelper.isDesktop() ? 8 : 0,
              children: cards,
            ),
          ],
        ),
      ),
    );
  }

  /// 统一的网格入口卡片(桌面150/移动80)
  Widget _buildGridCard({
    required Widget targetPage,
    required String title,
    required IconData icon,
    required Color accentColor,
    bool isNew = false,
  }) {
    return SizedBox(
      width: _cardSize,
      height: _cardSize,
      child: FeatureGridCard(
        targetPage: targetPage,
        title: title,
        icon: icon,
        accentColor: accentColor,
        isNew: isNew,
      ),
    );
  }
}
