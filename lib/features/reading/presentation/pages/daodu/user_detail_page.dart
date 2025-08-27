import 'package:flutter/material.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import 'user_snippets_page.dart';
import 'user_favourite_lessons_page.dart';
import 'user_thoughts_page.dart';

/// 用户详情页面（避免和其他用户详情页面歧义）
class DaoduUserDetailPage extends StatefulWidget {
  final String userId;

  const DaoduUserDetailPage({super.key, required this.userId});

  @override
  State<DaoduUserDetailPage> createState() => _DaoduUserDetailPageState();
}

class _DaoduUserDetailPageState extends State<DaoduUserDetailPage> {
  final ReadingApiManager _apiManager = ReadingApiManager();
  DaoduUserDetail? _userDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  /// 加载用户详情
  Future<void> _loadUserDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userDetail = await _apiManager.getDaoduUserDetail(
        id: widget.userId,
        // id: "5f0ae18889f0fe0006d86b67",
        forceRefresh: false,
      );

      setState(() {
        _userDetail = userDetail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserDetail,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUserDetail, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_userDetail == null) {
      return const Center(child: Text('用户信息不存在'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 用户头部信息
          _buildUserHeader(),

          const SizedBox(height: 16),

          // 用户统计信息
          _buildUserStats(),

          const SizedBox(height: 16),

          // 用户描述
          if (_userDetail!.sign?.isNotEmpty == true) ...[
            _buildUserDescription(),
            const SizedBox(height: 16),
          ],

          // 功能模块
          _buildFunctionModules(),

          // 底部间距
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // 头像
          CircleAvatar(
            radius: 50,
            backgroundImage: _userDetail!.avatar?.isNotEmpty == true
                ? NetworkImage(_userDetail!.avatar!)
                : null,
            child: _userDetail!.avatar?.isEmpty != false
                ? const Icon(Icons.person, size: 50)
                : null,
          ),

          const SizedBox(height: 16),

          // 用户名
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userDetail!.nickname ?? '未知用户',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // const SizedBox(width: 4),
              // Icon(_userDetail?.sex == 1 ? Icons.male : Icons.female, size: 16),
            ],
          ),
          const SizedBox(height: 8),

          // 用户ID
          Text(
            'ID: ${_userDetail!.id ?? ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          // 注册时间、更新时间
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '注册时间',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatTimestampToString(
                      _userDetail!.createdAt.toString(),
                      format: formatToYMD,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '上次签到',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatTimestampToString(
                      _userDetail!.lastCheckinTime.toString(),
                      format: formatToYMD,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            label: '总字数',
            value: _formatNumber(_userDetail!.wordsCount ?? 0),
            icon: Icons.text_fields,
            color: Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            label: '获赞数',
            value: _formatNumber(_userDetail!.receivedLikes ?? 0),
            icon: Icons.favorite_outline,
            color: Colors.red,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            label: '签到数',
            value: '${_userDetail!.sumCheckinTimes ?? 0}',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildUserDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '个人简介',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            _userDetail!.sign!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionModules() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '用户内容',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // 功能模块网格
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildModuleCard(
                title: '摘要',
                icon: Icons.note_outlined,
                color: Colors.blue,
                onTap: () => _navigateToSnippets(),
              ),
              _buildModuleCard(
                title: '想法',
                icon: Icons.lightbulb_outline,
                color: Colors.purple,
                onTap: () => _navigateToThoughts(),
              ),
              _buildModuleCard(
                title: '喜欢',
                icon: Icons.favorite_outline,
                color: Colors.red,
                onTap: () => _navigateToFavourites(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化数字显示
  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  void _navigateToSnippets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSnippetsPage(
          userId: widget.userId,
          userName: _userDetail?.nickname ?? '未知用户',
        ),
      ),
    );
  }

  void _navigateToThoughts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserThoughtsPage(
          userId: widget.userId,
          userName: _userDetail?.nickname ?? '未知用户',
        ),
      ),
    );
  }

  void _navigateToFavourites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFavouriteLessonsPage(
          userId: widget.userId,
          userName: _userDetail?.nickname ?? '未知用户',
        ),
      ),
    );
  }
}
