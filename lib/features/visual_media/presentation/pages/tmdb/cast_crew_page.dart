import 'package:flutter/material.dart';
import 'package:tmdb_api/tmdb_api.dart';

import '../../../data/datasources/tmdb/tmdb_apis.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../../data/models/tmdb/tmdb_mt_credit_resp.dart';
import '../../widgets/tmdb/base_widgets.dart';
import 'detail_page.dart';

/// TMDB 演职表页面
class TmdbCastCrewPage extends StatefulWidget {
  final String title;
  final TmdbMTCreditResp credits;

  const TmdbCastCrewPage({
    super.key,
    required this.title,
    required this.credits,
  });

  @override
  State<TmdbCastCrewPage> createState() => _TmdbCastCrewPageState();
}

class _TmdbCastCrewPageState extends State<TmdbCastCrewPage>
    with SingleTickerProviderStateMixin {
  final TmdbApiManager _apiManager = TmdbApiManager();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '演员 (${widget.credits.cast?.length ?? 0})'),
            Tab(text: '制作团队 (${widget.credits.crew?.length ?? 0})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCastList(), _buildCrewList()],
      ),
    );
  }

  /// 构建演员列表
  Widget _buildCastList() {
    final cast = widget.credits.cast;

    if (cast == null || cast.isEmpty) {
      return const TmdbEmptyWidget(
        message: '暂无演员信息',
        icon: Icons.person_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cast.length,
      itemBuilder: (context, index) {
        final person = cast[index];
        return _buildCastCard(person);
      },
    );
  }

  /// 构建制作团队列表
  Widget _buildCrewList() {
    final crew = widget.credits.crew;

    if (crew == null || crew.isEmpty) {
      return const TmdbEmptyWidget(
        message: '暂无制作团队信息',
        icon: Icons.work_outline,
      );
    }

    // 按部门分组
    final Map<String, List<TmdbCredit>> groupedCrew = {};
    for (final person in crew) {
      final department = person.department ?? '其他';
      groupedCrew.putIfAbsent(department, () => []).add(person);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedCrew.length,
      itemBuilder: (context, index) {
        final department = groupedCrew.keys.elementAt(index);
        final members = groupedCrew[department]!;

        return _buildCrewSection(department, members);
      },
    );
  }

  /// 构建演员卡片
  Widget _buildCastCard(TmdbCredit person) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TmdbImageWidget(
              imagePath: person.profilePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          person.name ?? '未知演员',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.character?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                '饰演: ${person.character}',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ],
            if (person.knownForDepartment?.isNotEmpty ?? false) ...[
              const SizedBox(height: 2),
              Text(
                '知名作品: ${person.knownForDepartment}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '人气: ${person.popularity?.toStringAsFixed(1) ?? '未知'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Text(
                  '排序: ${person.order != null ? (person.order! + 1) : '未知'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (person.id != null) {
            _navigateToPersonDetail(person.id!, person.name ?? '未知');
          }
        },
      ),
    );
  }

  /// 构建制作团队分区
  Widget _buildCrewSection(String department, List<TmdbCredit> members) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              department,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...members.map((person) => _buildCrewCard(person)),
          ],
        ),
      ),
    );
  }

  /// 构建制作团队卡片
  Widget _buildCrewCard(TmdbCredit person) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TmdbImageWidget(
                imagePath: person.profilePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name ?? '未知',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (person.job?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.job!,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
                if (person.knownForDepartment?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    '知名领域: ${person.knownForDepartment}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (person.id != null) {
                _navigateToPersonDetail(person.id!, person.name ?? '未知');
              }
            },
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }

  /// 跳转到人物详情页
  void _navigateToPersonDetail(int personId, String name) async {
    // 因为这里查询人物详情的接口不是TmdbResultItem类
    // 所以使用搜索接口，在找到的人物列表中匹配id相同的数据，传入详情页
    final personList = await _apiManager.search(
      name,
      mediaType: MediaType.person,
    );
    final personItem = personList.results?.firstWhere(
      (item) => item.id == personId,
      orElse: () => TmdbResultItem(),
    );

    if (personItem != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TmdbDetailPage(
            item: personItem,
            mediaType: personItem.mediaType ?? 'person',
          ),
        ),
      );
    }
  }
}
