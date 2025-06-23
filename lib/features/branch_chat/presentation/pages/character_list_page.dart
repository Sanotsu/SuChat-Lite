import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../core/utils/file_picker_utils.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../app/home_page.dart';
import '../../domain/entities/character_card.dart';
import '../viewmodels/character_store.dart';
import '../widgets/index.dart';
import 'character_editor_page.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  late final CharacterStore _store;
  List<CharacterCard> _characters = [];
  List<CharacterCard> _filteredCharacters = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    _store = await CharacterStore.create();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);

    _characters = _store.characters;
    _applyFilter();

    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCharacters = List.from(_characters);
    } else {
      _filteredCharacters =
          _characters.where((character) {
            return character.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                character.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                character.tags.any(
                  (tag) =>
                      tag.toLowerCase().contains(_searchQuery.toLowerCase()),
                );
          }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据平台类型选择不同的布局
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          // 角色卡列表
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCharacterGrid(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation:
          ScreenHelper.isDesktop()
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToCharacterEditor,
      tooltip: '添加新角色',
      child: const Icon(Icons.add),
    );
  }

  // 构建AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('角色列表'),
      titleSpacing: 8,
      actions: [
        if (ScreenHelper.isDesktop())
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCharacterEditor,
            tooltip: '添加新角色',
          ),

        IconButton(
          icon: const Icon(Icons.import_export),
          onPressed: _showImportExportDialog,
          tooltip: '角色备份',
        ),
      ],
    );
  }

  // 构建搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索角色...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilter();
          });
        },
      ),
    );
  }

  // 构建角色卡网格
  Widget _buildCharacterGrid() {
    // 根据平台类型决定网格布局
    final crossAxisCount =
        ScreenHelper.isDesktop()
            ? (MediaQuery.of(context).size.width / 240).floor().clamp(3, 6)
            : MediaQuery.of(context).size.width > 600
            ? 3
            : 2;

    return _filteredCharacters.isEmpty
        ? _buildEmptyState()
        : GridView.builder(
          padding: EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 6 / 9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredCharacters.length,
          itemBuilder: (context, index) {
            final character = _filteredCharacters[index];
            return CharacterCardItem(
              character: character,
              onTap: () => _handleCharacterTap(character),
              onEdit: () => _navigateToCharacterEditor(character: character),
              onDelete: () => _deleteCharacter(character),
            );
          },
        );
  }

  // 构建空状态提示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '没有找到任何角色',
            style: TextStyle(
              fontSize: ScreenHelper.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('清除搜索'),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _applyFilter();
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCharacterTap(CharacterCard character) async {
    if (character.preferredModel == null) {
      if (!mounted) return;
      commonHintDialog(
        context,
        '异常提示',
        '角色"${character.name}"未设置偏好模型，${ScreenHelper.isDesktop() ? '鼠标右键' : '长按该角色卡'}点击"编辑角色"',
      );

      return;
    }

    // 导航到HomePage并传递角色卡，保持与首页相同的结构以触发PopScope
    // 其实homepage就是带了character的branchchatpage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage(character: character)),
      (route) => false, // 完全清空路由栈
    );
  }

  // 长按删除角色卡
  Future<void> _deleteCharacter(CharacterCard character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除角色'),
            content: Text('确定要删除角色"${character.name}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _store.deleteCharacter(character.characterId);
      _loadCharacters();
    }
  }

  // 角色卡编辑页面的跳转方法
  void _navigateToCharacterEditor({CharacterCard? character}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterEditorPage(character: character),
      ),
    );

    if (result == true) {
      _loadCharacters();
    }
  }

  // 角色列表的导入导出对话框
  void _showImportExportDialog() async {
    bool isGranted = await requestStoragePermission();

    if (!mounted) return;
    if (!isGranted) {
      commonExceptionDialog(context, "异常提示", "无存储访问授权");
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('导入/导出'),
            content: SizedBox(
              width: ScreenHelper.isDesktop() ? 400 : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload),
                    title: const Text('导出角色'),
                    onTap: () {
                      Navigator.pop(context);
                      _exportCharacters();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('导入角色'),
                    onTap: () {
                      Navigator.pop(context);
                      _importCharacters();
                    },
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportCharacters() async {
    try {
      // 先让用户选择保存位置
      final directoryResult = await FilePicker.platform.getDirectoryPath();
      if (directoryResult == null) return; // 用户取消了选择

      final filePath = await _store.exportCharacters(
        customPath: directoryResult,
      );

      if (!mounted) return;

      commonHintDialog(context, '导出角色', '角色已导出到: $filePath');
    } catch (e) {
      if (!mounted) return;

      commonExceptionDialog(context, '导出角色', '导出失败: $e');
    }
  }

  Future<void> _importCharacters() async {
    try {
      // 1. 选择文件
      File? result = await FilePickerUtils.pickAndSaveFile(
        fileType: CusFileType.custom,
        allowedExtensions: ['json'],
        overwrite: true,
      );

      if (result == null) return;
      final importResult = await _store.importCharacters(result.path);

      if (!mounted) return;
      String message;
      if (importResult.importedCount > 0) {
        message = '成功导入 ${importResult.importedCount} 个角色';
        if (importResult.skippedCount > 0) {
          message += '，跳过 ${importResult.skippedCount} 个已存在的角色';
        }
      } else {
        message = '没有导入任何角色，所有角色已存在';
      }

      commonHintDialog(context, '导入角色', message);

      // 刷新列表
      _loadCharacters();
    } catch (e) {
      if (!mounted) return;

      commonExceptionDialog(context, '导入角色', '导入失败: $e');
    }
  }
}
