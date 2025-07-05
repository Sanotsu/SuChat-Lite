import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/note.dart';
import '../viewmodels/notebook_viewmodel.dart';
import '../widgets/note_card.dart';
import 'note_detail_page.dart';

class NotebookPage extends ConsumerStatefulWidget {
  const NotebookPage({super.key});

  @override
  ConsumerState<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends ConsumerState<NotebookPage> {
  NoteViewType _viewType = NoteViewType.grid;
  NoteFilterType _filterType = NoteFilterType.all;
  int? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  // 批量操作相关
  bool _isSelectMode = false;
  final Set<int> _selectedNoteIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 进入选择模式
  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _selectedNoteIds.clear();
    });
  }

  // 退出选择模式
  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedNoteIds.clear();
    });
  }

  // 切换笔记选中状态
  void _toggleNoteSelection(int noteId, bool selected) {
    setState(() {
      if (selected) {
        _selectedNoteIds.add(noteId);
      } else {
        _selectedNoteIds.remove(noteId);
      }
    });
  }

  // 全选/取消全选
  void _toggleSelectAll(List<Note> notes) {
    setState(() {
      if (_selectedNoteIds.length == notes.length) {
        // 如果全部已选中，则全部取消选中
        _selectedNoteIds.clear();
      } else {
        // 否则全部选中
        _selectedNoteIds.clear();
        for (final note in notes) {
          if (note.id != null) {
            _selectedNoteIds.add(note.id!);
          }
        }
      }
    });
  }

  // 批量归档选中的笔记
  Future<void> _batchArchiveNotes(List<Note> allNotes) async {
    if (_selectedNoteIds.isEmpty) return;

    // 获取选中的笔记
    final selectedNotes =
        allNotes
            .where(
              (note) => note.id != null && _selectedNoteIds.contains(note.id),
            )
            .toList();

    if (selectedNotes.isEmpty) return;

    // 显示确认对话框
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  '批量${_filterType == NoteFilterType.archived ? '取消归档' : '归档'}',
                ),
                content: Text(
                  '确定要${_filterType == NoteFilterType.archived ? '取消归档' : '归档'}选中的 ${selectedNotes.length} 个笔记吗？',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('确定'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final viewModel = ref.read(notebookViewModelProvider.notifier);

      // 根据当前筛选状态决定是批量归档还是批量取消归档
      if (_filterType == NoteFilterType.archived) {
        await viewModel.batchUnarchiveNotes(selectedNotes);
      } else {
        await viewModel.batchArchiveNotes(selectedNotes);
      }

      // 刷新笔记列表
      _refreshNotes();

      // 退出选择模式
      _exitSelectMode();

      // 显示成功提示
      if (mounted) {
        ToastUtils.showSuccess(
          '${selectedNotes.length} 个笔记${_filterType == NoteFilterType.archived ? '取消归档' : '归档'}成功',
        );
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        commonExceptionDialog(context, '操作失败', '操作失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 根据选择模式显示不同的标题
        title: buildAppBarTitle(),

        leading: buildAppBarLading(),

        actions:
            _isSelectMode
                // 选择模式下的操作按钮
                ? buildMultiSelectActions()
                // 非选择模式下的操作按钮
                : buildNonMultiSelectActions(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 非选择模式才显示分类列表
          if (!_isSelectMode) buildCategoryList(),

          // 笔记列表
          Expanded(child: buildNoteList()),
        ],
      ),
      // 非选择模式才显示悬浮按钮
      floatingActionButton:
          !_isSelectMode
              ? buildFloatingActionButton(
                _createNewNote,
                context,
                icon: Icons.add,
                tooltip: '添加笔记',
              )
              : null,
    );
  }

  /// ===========================
  /// 构建组件函数
  /// ===========================

  Widget buildAppBarTitle() {
    return _isSelectMode
        ? Text('已选择 ${_selectedNoteIds.length} 项')
        : Row(
          children: [
            const Text('记事本'),
            if (_filterType != NoteFilterType.all)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text(
                    _filterType == NoteFilterType.todo ? '待办事项' : '已归档',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () {
                    setState(() {
                      _filterType = NoteFilterType.all;
                      _refreshNotes();
                    });
                  },
                ),
              ),
          ],
        );
  }

  IconButton? buildAppBarLading() {
    return _isSelectMode
        ? IconButton(
          icon: const Icon(Icons.close),
          tooltip: '取消选择',
          onPressed: _exitSelectMode,
        )
        : null;
  }

  // 多选模式下按钮
  List<Widget> buildMultiSelectActions() {
    // 获取笔记数据
    final notesAsyncValue = ref.watch(notebookViewModelProvider);
    // 全选/取消全选按钮
    return [
      notesAsyncValue.when(
        data:
            (notes) => IconButton(
              icon: Icon(
                _selectedNoteIds.length == notes.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              tooltip: _selectedNoteIds.length == notes.length ? '取消全选' : '全选',
              onPressed: () => _toggleSelectAll(notes),
            ),
        loading: () => const SizedBox(),
        error: (_, _) => const SizedBox(),
      ),
      // 归档/取消归档按钮
      IconButton(
        icon: Icon(
          _filterType == NoteFilterType.archived
              ? Icons.unarchive
              : Icons.archive,
        ),
        tooltip: _filterType == NoteFilterType.archived ? '取消归档' : '归档',
        onPressed:
            () => notesAsyncValue.when(
              data: (notes) => _batchArchiveNotes(notes),
              loading: () {},
              error: (_, _) {},
            ),
      ),
    ];
  }

  // 非多选模式下按钮
  List<Widget> buildNonMultiSelectActions() {
    return [
      // 多选按钮
      IconButton(
        icon: const Icon(Icons.checklist),
        tooltip: '批量操作',
        onPressed: _enterSelectMode,
      ),
      // 搜索按钮
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          _showSearchDialog(context);
        },
      ),
      // 视图切换按钮
      IconButton(
        icon: Icon(
          _viewType == NoteViewType.grid ? Icons.view_list : Icons.grid_view,
        ),
        onPressed: () {
          setState(() {
            _viewType =
                _viewType == NoteViewType.grid
                    ? NoteViewType.list
                    : NoteViewType.grid;
          });
        },
      ),
      // 筛选按钮
      PopupMenuButton<NoteFilterType>(
        icon: const Icon(Icons.filter_list),
        tooltip: '筛选笔记',
        onSelected: (NoteFilterType result) {
          setState(() {
            _filterType = result;
            _refreshNotes();
          });
        },
        itemBuilder:
            (BuildContext context) => [
              PopupMenuItem<NoteFilterType>(
                value: NoteFilterType.all,
                child: Row(
                  children: [
                    const Text('全部笔记'),
                    const Spacer(),
                    if (_filterType == NoteFilterType.all)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              ),
              PopupMenuItem<NoteFilterType>(
                value: NoteFilterType.todo,
                child: Row(
                  children: [
                    const Text('待办事项'),
                    const Spacer(),
                    if (_filterType == NoteFilterType.todo)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              ),
              PopupMenuItem<NoteFilterType>(
                value: NoteFilterType.archived,
                child: Row(
                  children: [
                    const Text('已归档'),
                    const Spacer(),
                    if (_filterType == NoteFilterType.archived)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              ),
            ],
      ),
    ];
  }

  Widget buildCategoryList() {
    // 获取分类数据
    final categoriesAsyncValue = ref.watch(noteCategoryViewModelProvider);

    return categoriesAsyncValue.when(
      data: (categories) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1, // +1 是为了添加"全部"选项
            itemBuilder: (context, index) {
              // "全部"选项
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('全部'),
                    selected: _selectedCategoryId == null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategoryId = null;
                          _refreshNotes();
                        });
                      }
                    },
                  ),
                );
              }

              // 分类选项
              final category = categories[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    category.name,
                    style: TextStyle(color: Colors.white),
                  ),
                  selected: _selectedCategoryId == category.id,
                  backgroundColor: category.getCategoryColor(),
                  selectedColor: category.getCategoryColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategoryId = selected ? category.id : null;
                      _refreshNotes();
                    });
                  },
                ),
              );
            },
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => SizedBox(
            height: 50,
            child: Center(child: Text('加载笔记分类失败: $error')),
          ),
    );
  }

  Widget buildNoteList() {
    // 获取笔记数据
    final notesAsyncValue = ref.watch(notebookViewModelProvider);

    return notesAsyncValue.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const Center(child: Text('没有笔记，点击右下角按钮创建新笔记'));
        }

        // 根据视图类型显示不同的列表
        // 如果是网格视图
        if (_viewType == NoteViewType.grid) {
          // 如果是桌面端，固定卡片大小
          if (ScreenHelper.isDesktop()) {
            return SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.start,
                children:
                    notes
                        .map(
                          (note) => Container(
                            margin: const EdgeInsets.only(left: 8, bottom: 8),
                            width: 250,
                            height: 250,
                            child: NoteCard(
                              note: note,
                              onTap: () => _openNoteDetail(note),
                              isSelectable: _isSelectMode,
                              isSelected:
                                  note.id != null &&
                                  _selectedNoteIds.contains(note.id),
                              onSelected:
                                  note.id != null
                                      ? (selected) => _toggleNoteSelection(
                                        note.id!,
                                        selected,
                                      )
                                      : null,
                            ),
                          ),
                        )
                        .toList(),
              ),
            );
          }

          // 不是桌面端，就当作移动端，固定一行2个（平板也一样）
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.9,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => _openNoteDetail(note),
                isSelectable: _isSelectMode,
                isSelected:
                    note.id != null && _selectedNoteIds.contains(note.id),
                onSelected:
                    note.id != null
                        ? (selected) => _toggleNoteSelection(note.id!, selected)
                        : null,
              );
            },
          );
        }

        // 目前不是网格视图就是列表视图，所以没用else
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Container(
              padding: const EdgeInsets.only(bottom: 0),
              height: 150,
              child: NoteCard(
                note: note,
                isListView: true,
                onTap: () => _openNoteDetail(note),
                isSelectable: _isSelectMode,
                isSelected:
                    note.id != null && _selectedNoteIds.contains(note.id),
                onSelected:
                    note.id != null
                        ? (selected) => _toggleNoteSelection(note.id!, selected)
                        : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载笔记失败: $error')),
    );
  }

  /// ===========================
  /// 操作相关函数
  /// ===========================

  // 刷新笔记列表
  void _refreshNotes() {
    final notebookViewModel = ref.read(notebookViewModelProvider.notifier);

    // 根据筛选类型设置参数
    bool? isTodo;
    bool? isArchived;

    switch (_filterType) {
      case NoteFilterType.todo:
        isTodo = true;
        break;
      case NoteFilterType.archived:
        isArchived = true;
        break;
      case NoteFilterType.all:
    }

    notebookViewModel.refreshNotes(
      categoryId: _selectedCategoryId,
      isTodo: isTodo,
      isArchived: isArchived,
    );
  }

  // 显示搜索对话框
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('搜索笔记'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '输入关键词搜索笔记',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              if (value.isNotEmpty) {
                final notebookViewModel = ref.read(
                  notebookViewModelProvider.notifier,
                );
                notebookViewModel.refreshNotes(searchQuery: value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_searchController.text.isNotEmpty) {
                  final notebookViewModel = ref.read(
                    notebookViewModelProvider.notifier,
                  );
                  notebookViewModel.refreshNotes(
                    searchQuery: _searchController.text,
                  );
                }
              },
              child: const Text('搜索'),
            ),
          ],
        );
      },
    );
  }

  // 创建新笔记
  void _createNewNote() async {
    final result = await Navigator.push<Note?>(
      context,
      MaterialPageRoute(builder: (context) => const NoteDetailPage()),
    );

    if (result != null) {
      // 如果返回了笔记，刷新列表
      _refreshNotes();
    }
  }

  // 打开笔记详情
  void _openNoteDetail(Note note) async {
    final result = await Navigator.push<Note?>(
      context,
      MaterialPageRoute(builder: (context) => NoteDetailPage(note: note)),
    );

    if (result != null) {
      // 如果返回了笔记，刷新列表
      _refreshNotes();
    }
  }
}
