import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_chat_partner.dart';
import '../../data/database/unified_chat_dao.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import '../widgets/add_partner_dialog.dart';

/// 我的搭档页面
/// 在侧边栏和对话主页面新建对话时查看所有搭档会跳转到这个页面
/// 但是只有查看所有搭档时，点击某个搭档才将搭档数据返回上一页，其他的点击暂不操作
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

  Future<void> _addNewPartner() async {
    final result = await showDialog<UnifiedChatPartner>(
      context: context,
      builder: (context) => const AddPartnerDialog(),
    );

    if (result != null) {
      await _chatDao.saveChatPartner(result);
      _loadPartners();
      ToastUtils.showSuccess('搭档添加成功');
    }
  }

  Future<void> _editPartner(UnifiedChatPartner partner) async {
    final result = await showDialog<UnifiedChatPartner>(
      context: context,
      builder: (context) => AddPartnerDialog(partner: partner),
    );

    if (result != null) {
      await _chatDao.saveChatPartner(result);
      _loadPartners();
      ToastUtils.showSuccess('搭档更新成功');
    }
  }

  Future<void> _deletePartner(UnifiedChatPartner partner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除搭档'),
        content: Text('确定要删除搭档"${partner.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatDao.deleteChatPartner(partner.id);
      _loadPartners();
      ToastUtils.showSuccess('搭档已删除');
    }
  }

  Future<void> _toggleFavorite(UnifiedChatPartner partner) async {
    await _chatDao.togglePartnerFavorite(partner.id);
    _loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('我的搭档'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
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

  Widget _buildPartnerItem(UnifiedChatPartner partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),

        leading: buildUserCircleAvatar(
          partner.avatarUrl,
          backgroundColor: Colors.blue,
          radius: 16,
          defaultAvatar: Text(
            partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          partner.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          partner.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _toggleFavorite(partner),
              icon: Icon(
                partner.isFavorite ? Icons.star : Icons.star_border,
                color: partner.isFavorite ? Colors.orange : Colors.grey,
              ),
            ),

            if (!partner.isBuiltIn) ...[
              IconButton(
                onPressed: () => _editPartner(partner),
                icon: const Icon(Icons.edit, color: Colors.blue),
              ),
              IconButton(
                onPressed: () => _deletePartner(partner),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ],
        ),
        onTap: () {
          // 点击搭档进入对话页面
          if (widget.shouldReturnPartner == true) {
            Navigator.of(context).pop(partner);
          }
        },
      ),
    );
  }
}
