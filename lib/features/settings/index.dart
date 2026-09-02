import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/services/upgrade_migrator.dart';
import '../../core/utils/screen_helper.dart';
import '../../core/utils/simple_tools.dart';
import '../../core/viewmodels/user_info_viewmodel.dart';
import '../../shared/widgets/toast_utils.dart';
import 'pages/backup_and_restore_page.dart';
import 'pages/user_info_page.dart';

class UserAndSettings extends StatefulWidget {
  const UserAndSettings({super.key});

  @override
  State<UserAndSettings> createState() => _UserAndSettingsState();
}

class _UserAndSettingsState extends State<UserAndSettings> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    WidgetsFlutterBinding.ensureInitialized();

    final info = await PackageInfo.fromPlatform();

    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildUserInfoSection(theme),
              const SizedBox(height: 24),
              _buildSectionTitle('数据', theme),
              CusSettingCard(
                icon: Icons.backup_outlined,
                title: "备份恢复",
                description: "导出或恢复您的聊天数据",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackupAndRestorePage(
                      packageVersion: _packageInfo.version,
                    ),
                  ),
                ),
                accentColor: Colors.blue,
              ),
              CusSettingCard(
                icon: Icons.move_up,
                title: "旧版数据迁移",
                description: "从 0.1.4 旧版迁移数据到当前版本",
                onTap: () => _showLegacyMigrationSheet(context),
                accentColor: Colors.teal,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('支持', theme),
              CusSettingCard(
                icon: Icons.info_outline,
                title: '应用信息',
                description: '应用相关基础信息',
                onTap: _showAboutDialog,
                accentColor: Colors.orangeAccent,
              ),
              CusSettingCard(
                icon: Icons.help_outline,
                title: '常见问题(TBD)',
                description: '查看使用过程中常见问题的解答',
                onTap: () {},
                accentColor: Colors.green,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('关于', theme),
              CusSettingCard(
                icon: Icons.article_outlined,
                title: '用户协议(TBD)',
                description: '查看应用使用条款和条件',
                accentColor: Colors.purple,
                onTap: () {},
              ),
              CusSettingCard(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策(TBD)',
                description: '了解我们如何处理您的数据',
                accentColor: Colors.teal,
                onTap: () {},
              ),
              CusSettingCard(
                icon: Icons.security_outlined,
                title: '应用权限(TBD)',
                description: '管理应用所需的权限',
                accentColor: Colors.red,
                onTap: () {},
              ),
              const SizedBox(height: 24),
              _buildAppVersionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// 旧版数据迁移入口(0.1.5)：
  /// - 0.1.4 → 0.1.5 的库/媒体/配置由升级迁移器自动完成，此处可手动重跑
  /// - 旧聊天对话/角色只能经 0.1.4 全量备份 zip 中转导入
  /// 桌面端用居中弹窗(与其他弹窗风格一致)，移动端保持底部弹窗
  void _showLegacyMigrationSheet(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '升级到 0.1.5 时，旧版本的数据库、媒体与配置会自动迁移。\n'
              '旧版聊天对话与角色需通过旧版本的"全量备份"zip 导入。',
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.refresh, color: Colors.teal),
          title: const Text('重新扫描本机旧版数据'),
          subtitle: const Text('手动执行一次 0.1.4 数据自动迁移'),
          onTap: () async {
            Navigator.pop(context);
            // withLoading 保证结束(含异常)必关遮罩；
            // 之前直接 showLoading 不持有 CancelFunc，遮罩永不关闭锁死界面
            try {
              final result = await ToastUtils.withLoading(
                () => UpgradeMigrator.runIfNeeded(force: true),
                '正在扫描迁移旧版数据...',
              );
              ToastUtils.showSuccess(
                result.migrated ? '旧版数据迁移完成' : '未发现可迁移的旧版数据',
              );
            } catch (e) {
              ToastUtils.showError('旧版数据迁移失败: $e');
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.blue),
          title: const Text('从备份包导入旧聊天'),
          subtitle: const Text('选择 0.1.4 导出的全量备份 zip 恢复'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BackupAndRestorePage(packageVersion: _packageInfo.version),
              ),
            );
          },
        ),
      ],
    );

    if (ScreenHelper.isDesktop()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('旧版数据迁移'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: content,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '旧版数据迁移',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: content,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 SuChat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              _packageInfo.appName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('版本: ${_packageInfo.version} (${_packageInfo.buildNumber})'),
            const SizedBox(height: 16),
            _buildLinkButton(
              icon: Icons.code,
              label: "GitHub 项目",
              url: "https://github.com/Sanotsu/SuChat-Lite",
            ),
            // _buildLinkButton(
            //   icon: Icons.contact_support,
            //   label: "联系开发者",
            //   url: "callmedavidsu@gmail.com",
            // ),
            TextButton.icon(
              icon: Icon(Icons.contact_support, size: 18),
              label: Text('联系开发者'),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: 'callmedavidsu@gmail.com'),
                );
                ToastUtils.showSuccess('已复制开发者邮箱地址', align: Alignment.center);
              },
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget buildUserInfoSection(ThemeData theme) {
    return ChangeNotifierProvider(
      create: (context) => UserInfoViewModel(),
      child: Consumer<UserInfoViewModel>(
        builder: (context, viewModel, _) {
          // 初始化加载用户数据
          if (viewModel.currentUser == null && !viewModel.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.initialize();
            });
          }

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // 跳转到用户信息页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: viewModel,
                      child: const UserInfoPage(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.isLoading
                                ? '加载中...'
                                : viewModel.currentUser?.name ?? '未设置用户',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点击编辑个人信息',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.titleSmall?.color,
        ),
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => launchStringUrl(url),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size(double.infinity, 36),
        ),
      ),
    );
  }

  Widget _buildAppVersionInfo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '${_packageInfo.appName} v${_packageInfo.version}',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

class CusSettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback onTap;
  final Color? accentColor;
  final Widget? trailing;

  const CusSettingCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.onTap,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.disabledColor,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
