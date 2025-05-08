import 'package:flutter/material.dart';

import '../../common/components/feature_grid_card.dart';
import '../../common/utils/screen_helper.dart';

import 'image/index.dart';
import 'video/index.dart';
import 'voice/index.dart';
import 'voice_recog/voice_recognition_page.dart';

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
                margin:
                    ScreenHelper.isDesktop()
                        ? EdgeInsets.symmetric(horizontal: 32, vertical: 8)
                        : EdgeInsets.all(8),
                padding:
                    ScreenHelper.isDesktop()
                        ? EdgeInsets.all(24)
                        : EdgeInsets.all(16),
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

            // 桌面端避免窗口缩放后卡片变化不好看，就固定大小
            ScreenHelper.isDesktop()
                ? SliverToBoxAdapter(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: FeatureGridCard(
                          isNew: true,
                          targetPage: const VoiceRecognitionPage(),
                          title: "录音识别",
                          icon: Icons.audio_file,
                          accentColor: Colors.red.shade600,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: FeatureGridCard(
                          isNew: true,
                          targetPage: const BriefVoiceScreen(),
                          title: "语音合成",
                          icon: Icons.audiotrack,
                          accentColor: Colors.red.shade600,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: FeatureGridCard(
                          targetPage: const BriefImageScreen(),
                          title: "图片生成",
                          icon: Icons.image,
                          accentColor: Colors.orange.shade600,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: FeatureGridCard(
                          targetPage: const BriefVideoScreen(),
                          title: "视频生成",
                          icon: Icons.videocam,
                          accentColor: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                : SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ScreenHelper.isDesktop() ? 3 : 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildListDelegate([
                      // 2025-04-28不启用这两个是测试有从侧边栏跳转。但返回后无法更新修改的模型和角色等
                      // 实际上，这两个模块有其他入口，所以暂时不启用
                      // FeatureGridCard(
                      //   targetPage: const BriefModelConfig(),
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
                        isNew: true,
                        targetPage: const VoiceRecognitionPage(),
                        title: "录音识别",
                        icon: Icons.audio_file,
                        accentColor: Colors.red.shade600,
                      ),
                      FeatureGridCard(
                        isNew: true,
                        targetPage: const BriefVoiceScreen(),
                        title: "语音合成",
                        icon: Icons.audiotrack,
                        accentColor: Colors.red.shade600,
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
