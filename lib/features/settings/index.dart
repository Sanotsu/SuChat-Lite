import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

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
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BackupAndRestorePage(
                              packageVersion: _packageInfo.version,
                            ),
                      ),
                    ),
                accentColor: Colors.blue,
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('关于 SuChat'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  _packageInfo.appName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '版本: ${_packageInfo.version} (${_packageInfo.buildNumber})',
                ),
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
                    ToastUtils.showSuccess(
                      '已复制开发者邮箱地址',
                      align: Alignment.center,
                    );
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
                    builder:
                        (context) => ChangeNotifierProvider.value(
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
