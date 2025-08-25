import 'package:flutter/material.dart';

import '../core/utils/screen_helper.dart';
import '../shared/widgets/feature_grid_card.dart';
import '../shared/widgets/modern_feature_card.dart';
import 'model_management/index.dart';
import 'translator/presentation/pages/mini_translator_page.dart';
import 'visual_media/data/datasources/igdb/igdb_apis.dart';
import 'visual_media/presentation/pages/index.dart';
import 'diet_diary/presentation/index.dart';
import 'food/presentation/pages/douguo/recipe_home_page.dart';
import 'food/presentation/pages/usda_food_data/index.dart';
import 'funny_stuff/persentation/pages/index.dart';
import 'media_generation/image/presentation/index.dart';
import 'media_generation/video/presentation/index.dart';
import 'media_generation/voice/presentation/index.dart';
import 'news/presentation/pages/index.dart';
import 'notebook/presentation/pages/notebook_page.dart';
import 'simple_accounting/presentation/pages/bill_list_page.dart';
import 'training_assistant/presentation/index.dart';
import 'visual_media/presentation/pages/tmdb/tmdb_home_page.dart';
import 'voice_recognition/presentation/index.dart';

class AIToolPage extends StatefulWidget {
  const AIToolPage({super.key});

  @override
  State createState() => _AIToolPageState();
}

class _AIToolPageState extends State<AIToolPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更多功能'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ModelConfig()),
              );
            },
            child: Text('模型配置'),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 顶部横幅
            // if (ScreenHelper.isDesktop())
            topBanner(),

            // 免责声明
            disclaimer(),

            if (!ScreenHelper.isMobile()) deviceHint(),

            // 所有功能网格
            featureGridTitle(),
            // 桌面端避免窗口缩放后卡片变化不好看，就固定大小
            ScreenHelper.isDesktop()
                ? desktopFeatureGrid()
                : mobileFeatureGrid(),

            // 推荐功能
            extendedFeature(),

            // 娱乐功能
            entertainmentFeature(),

            // 底部间距
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter topBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: EdgeInsets.all(16),
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
                      Text(
                        "SuChat",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 8),
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
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter disclaimer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "所有由人工智能模型生成的内容，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度和观点",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  SliverToBoxAdapter deviceHint() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "本页面功能请在移动端设备中获得更佳体验；桌面端未进行适配，显示效果不佳。",
          style: TextStyle(fontSize: 16, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  SliverToBoxAdapter featureGridTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Text(
              "功能列表",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter desktopFeatureGrid() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Wrap(
          // alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: FeatureGridCard(
                targetPage: const GenVoicePage(),
                title: "语音合成",
                icon: Icons.audiotrack,
                accentColor: Colors.red,
              ),
            ),
            SizedBox(
              width: 150,
              height: 150,
              child: FeatureGridCard(
                targetPage: const GenImagePage(),
                title: "图片生成",
                icon: Icons.image,
                accentColor: Colors.green,
              ),
            ),
            SizedBox(
              width: 150,
              height: 150,
              child: FeatureGridCard(
                targetPage: const GenVideoPage(),
                title: "视频生成",
                icon: Icons.videocam,
                accentColor: Colors.blue,
              ),
            ),
            SizedBox(
              width: 150,
              height: 150,
              child: FeatureGridCard(
                isNew: true,
                targetPage: const VoiceRecognitionPage(),
                title: "录音识别",
                icon: Icons.audio_file,
                accentColor: Colors.orange,
              ),
            ),
            SizedBox(
              width: 150,
              height: 150,
              child: FeatureGridCard(
                isNew: true,
                targetPage: const MiniTranslatorPage(),
                title: "快速翻译",
                icon: Icons.translate,
                accentColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding mobileFeatureGrid() {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        delegate: SliverChildListDelegate([
          // 2025-04-28不启用这两个是测试有从侧边栏跳转。但返回后无法更新修改的模型和角色等
          // 实际上，这两个模块有其他入口，所以暂时不启用
          // FeatureGridCard(
          //   targetPage: const ModelConfig(),
          //   title: "模型配置",
          //   icon: Icons.settings,
          //   accentColor: Colors.blue.shade600,
          // ),
          // FeatureGridCard(
          //   targetPage: const CharacterListPage(),
          //   title: "角色扮演",
          //   icon: Icons.people_alt,
          //   accentColor: Colors.purple.shade600,
          // ),
          FeatureGridCard(
            targetPage: const GenVoicePage(),
            title: "语音合成",
            icon: Icons.audiotrack,
            accentColor: Colors.red,
          ),
          FeatureGridCard(
            targetPage: const GenImagePage(),
            title: "图片生成",
            icon: Icons.image,
            accentColor: Colors.green,
          ),
          FeatureGridCard(
            targetPage: const GenVideoPage(),
            title: "视频生成",
            icon: Icons.videocam,
            accentColor: Colors.blue,
          ),
          FeatureGridCard(
            isNew: true,
            targetPage: const VoiceRecognitionPage(),
            title: "录音识别",
            icon: Icons.audio_file,
            accentColor: Colors.orange,
          ),
          FeatureGridCard(
            isNew: true,
            targetPage: const MiniTranslatorPage(),
            title: "快速翻译",
            icon: Icons.translate,
            accentColor: Colors.purple,
          ),
        ]),
      ),
    );
  }

  SliverToBoxAdapter extendedFeature() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                SizedBox(width: 8),
                Text(
                  "扩展功能",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ModernFeatureCard(
                    targetPage: const TrainingAssistantPage(),
                    title: "训练助手",
                    subtitle: "使用大模型生成健身训练计划，可灵活跟练，强身健体",
                    icon: Icons.fitness_center,
                    accentColor: Colors.indigo,
                    showArrow: ScreenHelper.isDesktop(),
                    showSubtitle: ScreenHelper.isDesktop(),
                  ),
                ),
                SizedBox(width: ScreenHelper.isDesktop() ? 16 : 4),
                Expanded(
                  child: ModernFeatureCard(
                    targetPage: const DietDiaryPage(),
                    title: "饮食日记",
                    subtitle: "记录每日饮食，定制食谱；分析营养成分，食品管理",
                    icon: Icons.restaurant,
                    accentColor: Colors.indigo,
                    showArrow: ScreenHelper.isDesktop(),
                    showSubtitle: ScreenHelper.isDesktop(),
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenHelper.isDesktop() ? 16 : 4),
            Row(
              children: [
                Expanded(
                  child: ModernFeatureCard(
                    targetPage: const BillListPage(),
                    title: "极简记账",
                    subtitle: "手动记账，支持简单分类管理，周度、月度、年度统计",
                    icon: Icons.money,
                    accentColor: Colors.indigo,
                    showArrow: ScreenHelper.isDesktop(),
                    showSubtitle: ScreenHelper.isDesktop(),
                  ),
                ),

                SizedBox(width: ScreenHelper.isDesktop() ? 16 : 4),
                Expanded(
                  child: ModernFeatureCard(
                    targetPage: const NotebookPage(),
                    title: "记事本",
                    subtitle: "轻量记事本，富文本编辑，随时记录灵感，高效管理",
                    icon: Icons.note_alt,
                    accentColor: Colors.indigo,
                    showArrow: ScreenHelper.isDesktop(),
                    showSubtitle: ScreenHelper.isDesktop(),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 12),
            // ModernFeatureCard(
            //   targetPage: const TrainingAssistantPage(),
            //   title: "训练助手",
            //   subtitle: "使用大模型生成健身训练计划，可灵活跟练，强身健体",
            //   icon: Icons.fitness_center,
            //   accentColor: Colors.indigo,
            // ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter entertainmentFeature() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                SizedBox(width: 8),
                Text(
                  "生活娱乐",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            Wrap(
              // spacing: 8,
              // runSpacing: 8,
              // alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 80,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: FeatureGridCard(
                    targetPage: const NewsIndex(),
                    title: "新闻热榜",
                    icon: Icons.newspaper,
                    accentColor: Colors.orange,
                  ),
                ),

                //  _rowWidget([
                //     LifeToolEntranceCard(
                //       title: "热量计算器",
                //       subtitle: "食物热量和运动消耗",
                //       icon: Icons.calculate,
                //       onTap: () => showNoNetworkOrGoTargetPage(
                //         context,
                //         NixSimpleCalculator(),
                //       ),
                //     ),
                //     const SizedBox(),
                //   ]),
                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 80,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: FeatureGridCard(
                    targetPage: const FunnyStuffIndex(),
                    title: "趣图趣文",
                    icon: Icons.image,
                    accentColor: Colors.orange,
                  ),
                ),

                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 80,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: FeatureGridCard(
                    targetPage: const VisualMediaIndex(),
                    title: "图片动漫",
                    icon: Icons.collections_bookmark,
                    accentColor: Colors.orange,
                  ),
                ),

                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 80,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: FeatureGridCard(
                    targetPage: const TmdbHomePage(),
                    title: "TMDB",
                    icon: Icons.movie,
                    accentColor: Colors.orange,
                  ),
                ),

                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 80,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: FeatureGridCard(
                    targetPage: const RecipeHomePage(),
                    title: "豆果美食",
                    icon: Icons.menu_book,
                    accentColor: Colors.orange,
                  ),
                ),

                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 80,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: TextButton(
                    onPressed: getIgdbAccessToken,
                    child: Text("IGDB\n(TODO)"),
                  ),
                ),
              ],
            ),

            Wrap(
              // spacing: 8,
              // runSpacing: 8,
              // alignment: WrapAlignment.center,
              children: [
                SizedBox(
                  width: ScreenHelper.isDesktop() ? 150 : 120,
                  height: ScreenHelper.isDesktop() ? 150 : 80,
                  child: FeatureGridCard(
                    targetPage: const USDAFoodDataCentral(),
                    title: "USDA FDC",
                    icon: Icons.calculate,
                    accentColor: Colors.orange,
                  ),
                ),
              ],
            ),

            // SizedBox(height: 12),
            // ModernFeatureCard(
            //   targetPage: const TrainingAssistantPage(),
            //   title: "训练助手",
            //   subtitle: "使用大模型生成健身训练计划，可灵活跟练，强身健体",
            //   icon: Icons.fitness_center,
            //   accentColor: Colors.indigo,
            // ),
          ],
        ),
      ),
    );
  }
}
