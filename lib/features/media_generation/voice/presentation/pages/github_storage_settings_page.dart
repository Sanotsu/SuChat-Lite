import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/widgets/toast_utils.dart';
import '../../../../../core/theme/style/app_colors.dart';
import '../../../../../core/storage/cus_get_storage.dart';
import '../../../../../shared/services/github_storage_service.dart';

class GitHubStorageSettingsPage extends StatefulWidget {
  const GitHubStorageSettingsPage({super.key});

  @override
  State<GitHubStorageSettingsPage> createState() =>
      _GitHubStorageSettingsPageState();
}

class _GitHubStorageSettingsPageState extends State<GitHubStorageSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _repoController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _repoController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  // 加载已保存的设置
  Future<void> _loadSettings() async {
    final storage = CusGetStorage();
    setState(() {
      _usernameController.text = storage.getGithubUsername();
      _repoController.text = storage.getGithubRepo();
      _tokenController.text = storage.getGithubToken();
    });
  }

  // 验证并保存设置
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = CusGetStorage();

      // 如果所有字段都为空，则清除配置
      if (_usernameController.text.isEmpty &&
          _repoController.text.isEmpty &&
          _tokenController.text.isEmpty) {
        await storage.setGithubUsername(null);
        await storage.setGithubRepo(null);
        await storage.setGithubToken(null);
        ToastUtils.showToast('已清除GitHub配置');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 验证GitHub配置
      if (_usernameController.text.isNotEmpty &&
          _repoController.text.isNotEmpty &&
          _tokenController.text.isNotEmpty) {
        // 创建GitHub存储服务并测试连接
        final githubStorage = GitHubStorageService(
          username: _usernameController.text,
          repoName: _repoController.text,
          accessToken: _tokenController.text,
        );

        // 验证凭证
        final isValid = await githubStorage.validateCredentials();

        await githubStorage.ensureDirectoryExists();
        if (!isValid) {
          ToastUtils.showError('GitHub凭证验证失败，请检查用户名和访问令牌');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // 保存配置
        await storage.setGithubUsername(_usernameController.text);
        await storage.setGithubRepo(_repoController.text);
        await storage.setGithubToken(_tokenController.text);

        ToastUtils.showSuccess('GitHub配置已保存并验证成功');
      } else {
        ToastUtils.showError('请完整填写所有字段');
        setState(() {
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      ToastUtils.showError('保存设置失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub存储设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '使用说明',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                '配置GitHub存储服务',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '使用GitHub存储需要一个公开仓库，用于存储音频文件。您需要提供GitHub用户名、仓库名和具有仓库写入权限的个人访问令牌。',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // GitHub用户名
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'GitHub用户名',
                  hintText: '例如：username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入GitHub用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GitHub仓库名
              TextFormField(
                controller: _repoController,
                decoration: const InputDecoration(
                  labelText: 'GitHub仓库名',
                  hintText: '例如：my-audio-repo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入GitHub仓库名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GitHub访问令牌
              TextFormField(
                controller: _tokenController,
                obscureText: _obscureToken,
                decoration: InputDecoration(
                  labelText: 'GitHub个人访问令牌',
                  hintText: '例如：ghp_XXX...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureToken ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureToken = !_obscureToken;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入GitHub个人访问令牌';
                  }
                  if (!value.startsWith('ghp_') &&
                      !value.startsWith('github_pat_')) {
                    return '令牌格式不正确，应以ghp_或github_pat_开头';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 保存按钮
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('验证中...'),
                          ],
                        )
                        : const Text('保存并验证'),
              ),
              const SizedBox(height: 16),

              // 清除按钮
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _usernameController.clear();
                            _repoController.clear();
                            _tokenController.clear();
                          });
                        },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清除所有配置'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示帮助对话框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('GitHub存储使用说明'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '1. 创建GitHub公开仓库',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('在GitHub上创建一个公开仓库，用于存储音频文件。'),
                  SizedBox(height: 8),

                  Text(
                    '2. 生成个人访问令牌',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '访问GitHub设置→开发者设置→个人访问令牌→生成新令牌。\n选择"repo"权限，设置一个合适的过期时间。',
                  ),
                  SizedBox(height: 8),

                  Text(
                    '3. 配置存储设置',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('将您的GitHub用户名、仓库名和访问令牌填入表单中。\n点击"保存并验证"按钮进行验证。'),
                  SizedBox(height: 8),

                  Text(
                    '注意事项',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    '- 请确保使用公开仓库，否则无法访问上传的文件。\n- 保管好您的访问令牌，不要泄露给他人。\n- 音频文件将以公开形式存储，请不要上传敏感内容。',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'https://github.com/settings/tokens/new',
                    ),
                  );
                  ToastUtils.showToast('GitHub令牌创建链接已复制');
                },
                child: const Text('复制令牌创建链接'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }
}
