import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/components/tool_widget.dart';

import 'backup_and_restore/index.dart';

class UserAndSettings extends StatefulWidget {
  const UserAndSettings({super.key});

  @override
  State<UserAndSettings> createState() => _UserAndSettingsState();
}

class _UserAndSettingsState extends State<UserAndSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户设置')),
      body: ListView(
        children: [
          SizedBox(height: 10.sp),

          CusSettingCard(
            leadingIcon: Icons.backup_outlined,
            trailingIcon: Icons.arrow_forward_ios,
            title: "备份恢复",
            onTap: () {
              // 处理相应的点击事件
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupAndRestore(),
                ),
              );
            },
          ),
          CusSettingCard(
            leadingIcon: Icons.question_mark,
            title: '常见问题(TBD)',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SuChat',
                children: [
                  const Center(child: Text("author & wechat: SanotSu")),
                  TextButton(
                    onPressed: () {
                      launchStringUrl("https://github.com/Sanotsu/SuChat-Lit");
                    },
                    child: const Text("Github: Sanotsu/SuChat-Lit"),
                  ),
                ],
              );
            },
          ),
          CusSettingCard(
            leadingIcon: Icons.article_outlined,
            title: '用户协议(TBD)',
            onTap: () {},
          ),
          CusSettingCard(
            leadingIcon: Icons.privacy_tip_outlined,
            title: '隐私政策(TBD)',
            onTap: () {},
          ),
          CusSettingCard(
            leadingIcon: Icons.security_outlined,
            title: '应用权限(TBD)',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// 每个设置card抽出来复用
class CusSettingCard extends StatelessWidget {
  final IconData leadingIcon;
  final IconData? trailingIcon;
  final String title;
  final VoidCallback onTap;

  const CusSettingCard({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.sp),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.sp),
        ),
        child: Center(
          child: ListTile(
            leading: Icon(leadingIcon),
            trailing: Icon(trailingIcon, size: 16),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
