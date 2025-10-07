import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/unified_chat_partner.dart';
import '../../data/database/unified_chat_dao.dart';
import '../pages/my_partners_page.dart';
import '../viewmodels/unified_chat_viewmodel.dart';

/// 搭档横向滚动列表组件
class PartnerHorizontalList extends StatefulWidget {
  final Function(UnifiedChatPartner) onPartnerSelected;

  const PartnerHorizontalList({super.key, required this.onPartnerSelected});

  @override
  State<PartnerHorizontalList> createState() => _PartnerHorizontalListState();
}

class _PartnerHorizontalListState extends State<PartnerHorizontalList> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  List<UnifiedChatPartner> _partners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);

    try {
      // 加载收藏的搭档和部分内置搭档
      final favoritePartners = await _chatDao.getChatPartners(isActive: true);

      // 只显示前几个搭档，避免列表过长
      final displayPartners = favoritePartners.take(6).toList();

      setState(() {
        _partners = displayPartners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_partners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _partners.length + 1,
              itemBuilder: (context, index) {
                // 最后一个显示更多，点击调转到搭档列表页面
                if (index == _partners.length) {
                  return _buildGetAllPartnerItem();
                }

                return _buildPartnerItem(_partners[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerItem(UnifiedChatPartner partner) {
    return GestureDetector(
      onTap: () => widget.onPartnerSelected(partner),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: partner.isFavorite ? Colors.orange : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 头像
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: partner.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        partner.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(partner);
                        },
                      ),
                    )
                  : _buildDefaultAvatar(partner),
            ),
            const SizedBox(width: 4),
            // 名称
            Text(
              partner.name.length > 4
                  ? "${partner.name.substring(0, 4)}…"
                  : partner.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetAllPartnerItem() {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyPartnersPage(shouldReturnPartner: true),
              ),
            ).then((value) {
              viewModel.refreshUserPreferences();

              if (value != null && value is UnifiedChatPartner) {
                widget.onPartnerSelected(value);
              }
            });
          },

          child: Container(
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 4),
                Text(
                  '查看所有搭档',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(UnifiedChatPartner partner) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }
}
