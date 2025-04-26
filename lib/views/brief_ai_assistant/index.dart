import 'package:flutter/material.dart';

import '../../common/components/feature_grid_card.dart';

import '../../common/utils/screen_helper.dart';
import 'branch_chat/pages/character_list_page.dart';
import 'image/index.dart';
import 'model_config/index.dart';
import 'video/index.dart';
import 'voice/index.dart';

class BriefAITools extends StatefulWidget {
  const BriefAITools({super.key});

  @override
  State createState() => _BriefAIToolsState();
}

class _BriefAIToolsState extends State<BriefAITools> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('更多功能')),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 顶部横幅
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.2),
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
                              // IconButton(
                              //   onPressed: () async {
                              //     await Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //         builder:
                              //             (context) => const BriefModelConfig(),
                              //       ),
                              //     );
                              //   },
                              //   icon: const Icon(
                              //     Icons.settings,
                              //     color: Colors.white,
                              //   ),
                              //   tooltip: '模型配置',
                              // ),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 免责声明
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "所有内容均由人工智能模型生成，无法确保内容的真实性、准确性和完整性，仅供参考，且不代表开发者的态度和观点",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 所有功能网格
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "功能列表",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ScreenHelper.isDesktop() ? 4 : 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildListDelegate([
                  FeatureGridCard(
                    targetPage: const BriefModelConfig(),
                    title: "模型配置",
                    icon: Icons.settings,
                    accentColor: Colors.blue.shade600,
                  ),
                  FeatureGridCard(
                    targetPage: const CharacterListPage(),
                    title: "角色扮演",
                    icon: Icons.people_alt,
                    accentColor: Colors.purple.shade600,
                  ),
                  FeatureGridCard(
                    targetPage: const BriefImageScreen(),
                    title: "图片生成",
                    icon: Icons.image,
                    accentColor: Colors.orange.shade600,
                  ),
                  FeatureGridCard(
                    targetPage: const BriefVideoScreen(),
                    title: "视频生成",
                    icon: Icons.videocam,
                    accentColor: Colors.red.shade600,
                  ),
                  FeatureGridCard(
                    targetPage: const BriefVoiceScreen(),
                    title: "语音合成",
                    icon: Icons.audiotrack,
                    accentColor: Colors.red.shade600,
                  ),
                ]),
              ),
            ),

            // 底部间距
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
