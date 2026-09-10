import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_chat_partner.dart';
import '../../data/database/unified_chat_dao.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'partner_detail_page.dart';
import 'partner_edit_page.dart';

/// 我的搭档页面
/// 在侧边栏和对话主页面新建对话时查看所有搭档会跳转到这个页面
/// 但是只有查看所有搭档时，点击某个搭档才将搭档数据返回上一页，其他的点击进详情页
/// 2026-09-07 重构：
/// 点击列表项进入搭档详情页(内置/自制均可查看)，编辑/删除收敛到详情页；
/// 新建搭档由弹窗改为独立编辑页；列表项仅保留收藏按钮；
/// 页面包 CusContentWidth 做桌面限宽适配
class MyPartnersPage extends StatefulWidget {
  final bool? shouldReturnPartner;
  const MyPartnersPage({this.shouldReturnPartner = false, super.key});

  @override
  State<MyPartnersPage> createState() => _MyPartnersPageState();
}

class _MyPartnersPageState extends State<MyPartnersPage> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();

  List<UnifiedChatPartner> _myPartners = [];
  List<UnifiedChatPartner> _builtInPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _saveShowPartnersInChatSetting(
    bool value,
    UnifiedChatViewModel viewModel,
  ) async {
    try {
      await viewModel.updateShowPartnersInNewChat(value);
      ToastUtils.showSuccess(value ? '已开启在新对话中显示搭档' : '已关闭在新对话中显示搭档');
    } catch (e) {
      ToastUtils.showError('保存设置失败: $e');
    }
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);

    try {
      // 加载用户自定义搭档
      final myPartners = await _chatDao.getChatPartners(
        isBuiltIn: false,
        isActive: true,
      );

      // 加载内置搭档
      final builtInPartners = await _chatDao.getChatPartners(
        isBuiltIn: true,
        isActive: true,
      );

      setState(() {
        _myPartners = myPartners;
        _builtInPartners = builtInPartners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('加载搭档列表失败: $e');
    }
  }

  /// 新建搭档：跳转编辑页，返回搭档对象后保存
  Future<void> _addNewPartner() async {
    final result = await Navigator.push<UnifiedChatPartner>(
      context,
      MaterialPageRoute(builder: (context) => const PartnerEditPage()),
    );

    if (result != null) {
      await _chatDao.saveChatPartner(result);
      _loadPartners();
      ToastUtils.showSuccess('搭档添加成功');
    }
  }

  Future<void> _toggleFavorite(UnifiedChatPartner partner) async {
    await _chatDao.togglePartnerFavorite(partner.id);
    _loadPartners();
  }

  /// 点击列表项：选择模式下返回搭档数据，否则进详情页
  Future<void> _openPartnerDetail(UnifiedChatPartner partner) async {
    if (widget.shouldReturnPartner == true) {
      Navigator.of(context).pop(partner);
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerDetailPage(partner: partner),
      ),
    );

    // 详情页内发生编辑/删除时刷新列表
    if (changed == true) _loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    return CusContentWidth.form(
      child: Consumer<UnifiedChatViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('我的搭档'), elevation: 0),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 设置开关
                        _buildShowSwitch(viewModel),

                        // 搭档列表
                        ..._buildPartnerList(),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Container _buildShowSwitch(UnifiedChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: viewModel.showPartnersInNewChat,
                onChanged: (value) =>
                    _saveShowPartnersInChatSetting(value, viewModel),
              ),
              const SizedBox(width: 12),
              const Text('在新对话中显示我的搭档'),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPartnerList() {
    List<Widget> cusPartnerList = [];

    // 自定义搭档列表
    if (_myPartners.isEmpty) {
      cusPartnerList.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text('还没有自定义搭档', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addNewPartner,
                child: const Text('创建第一个搭档'),
              ),
            ],
          ),
        ),
      );
    } else {
      cusPartnerList.addAll(_myPartners.map(_buildPartnerItem));
    }

    return [
      Row(
        children: [
          const Text(
            '自制搭档',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _addNewPartner,
            icon: const Icon(Icons.add, color: Colors.blue),
            label: const Text('创建新的AI搭档', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...cusPartnerList,
      const SizedBox(height: 32),

      // 内置搭档
      const Text(
        '内置搭档',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),

      ..._builtInPartners.map(_buildPartnerItem),
    ];
  }

  /// 列表项：2026-09-07 移除编辑/删除按钮(收敛到详情页)，点击进详情
  Widget _buildPartnerItem(UnifiedChatPartner partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 12, 0),

        leading: buildUserCircleAvatar(
          partner.avatarUrl,
          backgroundColor: Colors.blue,
          radius: 16,
          defaultAvatar: Text(
            partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                partner.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 6),
            if (partner.isBuiltIn)
              Text(
                '(内置)',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade400),
              ),
          ],
        ),
        subtitle: Text(
          partner.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: IconButton(
          onPressed: () => _toggleFavorite(partner),
          icon: Icon(
            partner.isFavorite ? Icons.star : Icons.star_border,
            color: partner.isFavorite ? Colors.orange : Colors.grey,
          ),
        ),
        onTap: () => _openPartnerDetail(partner),
      ),
    );
  }
}
