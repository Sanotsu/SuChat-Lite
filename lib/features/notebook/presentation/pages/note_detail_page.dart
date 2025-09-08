import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/common_dialog.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_category.dart';
import '../../domain/entities/note_tag.dart';
import '../../domain/entities/note_media.dart';
import '../viewmodels/notebook_viewmodel.dart';
import '../widgets/create_color_item_dialog.dart';
import '../widgets/note_audio_recorder.dart';
import '../widgets/note_audio_list.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final Note? note; // 如果为 null，则是创建新笔记

  const NoteDetailPage({super.key, this.note});

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late bool _isTodo;
  late bool _isCompleted;
  late bool _isPinned;
  late bool _isArchived;
  late bool _isReadOnly;

  int? _selectedCategoryId;
  List<NoteTag> _selectedTags = [];
  int? _selectedColor;

  // 当前正在编辑的笔记
  Note? _currentNote;

  bool _isEdited = false;
  bool _isLoading = false;
  // 自动保存定时器
  Timer? _autoSaveTimer;

  // 移动端的工具栏状态
  bool _showMobileToolbar = false;

  // 为QuillEditor添加FocusNode并管理其焦点状态
  // 不添加这个会出现在编辑正文时莫名其妙就聚焦到标题输入框了
  // 但只需要添加这个在quill编辑器不做其他操作自动保存后也正常聚焦了
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // 初始化当前笔记
    _currentNote = widget.note;

    // 初始化标题控制器
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    // 初始化富文本编辑器
    if (widget.note != null && widget.note!.contentDelta.isNotEmpty) {
      try {
        // 尝试从 contentDelta 解析 Delta
        final dynamic deltaJson = jsonDecode(widget.note!.contentDelta);
        final document = Document.fromJson(deltaJson);
        _quillController = QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        debugPrint('解析笔记 Delta 内容失败: $e');
        _quillController = QuillController.basic();
      }
    } else {
      // 创建新笔记或没有 Delta 内容
      _quillController = QuillController.basic();
    }

    // 初始化其他状态
    if (widget.note != null) {
      _isTodo = widget.note!.isTodo;
      _isCompleted = widget.note!.isCompleted;
      _isPinned = widget.note!.isPinned;
      _isArchived = widget.note!.isArchived;
      _isReadOnly = widget.note!.isArchived;
      _selectedCategoryId = widget.note!.categoryId;
      _selectedTags = List.from(widget.note!.tags);
      _selectedColor = widget.note!.color;

      // 如果笔记已归档，设置为只读模式
      if (_isReadOnly) {
        _quillController.readOnly = true; // 设置富文本编辑器为只读
      }
    } else {
      // 创建新笔记
      _isTodo = false;
      _isCompleted = false;
      _isPinned = false;
      _isArchived = false;
      _isReadOnly = false;
    }

    // 监听变化
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);

    // 启动自动保存定时器（非只读模式下）
    if (!_isReadOnly) {
      _startAutoSaveTimer();
    }
  }

  @override
  void dispose() {
    // 取消定时器
    _autoSaveTimer?.cancel();

    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  // 启动自动保存定时器
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // 如果有编辑且不是只读，则自动保存
      if (_isEdited && !_isReadOnly && mounted) {
        _autoSave();
      }
    });
  }

  // 自动保存方法
  Future<void> _autoSave() async {
    if (!_isEdited || _isReadOnly) return;

    try {
      // 使用静默模式保存，不显示加载圈
      await _saveNote(silent: true);

      if (mounted) {
        setState(() {
          _isEdited = false;
        });
      }
    } catch (e) {
      // 自动保存失败不显示错误，避免打扰用户
      debugPrint('自动保存失败: $e');
    }
  }

  // 内容变化监听
  void _onContentChanged() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }

  // 切换移动端工具栏显示状态
  void _toggleMobileToolbar() {
    setState(() {
      _showMobileToolbar = !_showMobileToolbar;
    });
  }

  // 保存笔记
  // silent 时不显示加载圈，也不显示保存成功文字
  Future<void> _saveNote({bool silent = false}) async {
    // 只有在非静默模式下才更新UI显示加载状态
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final notebookViewModel = ref.read(notebookViewModelProvider.notifier);

      // 获取纯文本内容
      final plainText = _quillController.document.toPlainText().trim();

      // 获取Delta JSON
      final deltaJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );

      // 如果标题为空，则使用正文的前30个字符作为标题
      String title = _titleController.text.trim();
      if (title.isEmpty && plainText.isNotEmpty) {
        // 截取正文的前30个字符作为标题
        title = plainText.length > 30 ? plainText.substring(0, 30) : plainText;
        // 如果标题包含换行符，只取第一行
        final firstLineEnd = title.indexOf('\n');
        if (firstLineEnd > 0) {
          title = title.substring(0, firstLineEnd);
        }
      }

      Note? savedNote;

      if (_currentNote == null) {
        // 创建新笔记
        savedNote = await notebookViewModel.createNote(
          title: title,
          content: plainText,
          contentDelta: deltaJson,
          categoryId: _selectedCategoryId,
          isTodo: _isTodo,
          color: _selectedColor,
          isPinned: _isPinned,
          tags: _selectedTags,
        );

        // 更新当前笔记引用
        if (mounted) {
          setState(() {
            _currentNote = savedNote;
          });
        }

        // 只在非静默模式下返回
        if (mounted && !silent) {
          Navigator.pop(context, savedNote);
        }
      } else {
        // 更新笔记
        final updatedNote = _currentNote!.copyWith(
          title: title,
          content: plainText,
          contentDelta: deltaJson,
          categoryId: _selectedCategoryId,
          isTodo: _isTodo,
          isCompleted: _isCompleted,
          isPinned: _isPinned,
          isArchived: _isArchived, // 确保使用最新的归档状态
          color: _selectedColor,
          tags: _selectedTags,
          updatedAt: DateTime.now(),
        );

        // 根据归档状态选择适当的更新方法
        savedNote = _isArchived
            ? await notebookViewModel.archiveNote(updatedNote)
            : await notebookViewModel.updateNote(updatedNote);

        // 更新当前笔记引用
        if (mounted) {
          setState(() {
            _currentNote = savedNote;
          });
        }

        // 只在非静默模式下返回
        if (mounted && !silent) {
          Navigator.pop(context, savedNote);
        }
      }

      // 显示保存成功消息
      if (mounted && !silent) {
        ToastUtils.showToast('保存笔记成功');
      }
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, '保存笔记失败', '保存笔记失败: $e');
      }
    } finally {
      // 只有在非静默模式下才更新UI隐藏加载状态
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 处理返回按钮事件
  Future<bool> _onWillPop() async {
    // 如果笔记已编辑且不是只读模式，则保存笔记
    if (_isEdited && !_isReadOnly) {
      // 显示保存确认对话框
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('保存笔记'),
          content: const Text('是否保存当前笔记？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('不保存'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      );

      // 如果用户选择保存，则保存笔记
      if (result == true) {
        // 使用静默模式保存，避免显示加载圈
        await _saveNote(silent: true);

        // 如果是新创建的笔记，将结果返回给上一个页面
        if (mounted && _currentNote != null && widget.note == null) {
          Navigator.pop(context, _currentNote);
          return false; // 已经手动处理了导航，不需要再次弹出
        }
      }
    }
    return true; // 允许返回
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_isEdited && !_isReadOnly),
      onPopInvokedWithResult: (didPop, Object? result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
          actions: buildActions(),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ScreenHelper.isDesktop()
            // 如果是桌面端，则直接使用commonLayout，编辑器内部使用Expanded填充满剩下的区域
            ? commonLayout()
            // 如果是移动端，则使用可滚动组件包裹，且设定编辑器一个固定高度
            : SingleChildScrollView(child: commonLayout()),
        floatingActionButton: _isReadOnly
            ? null
            : Stack(
                children: [
                  buildFloatingActionButton(
                    _saveNote,
                    context,
                    icon: Icons.save,
                    tooltip: '保存笔记',
                  ),
                ],
              ),
      ),
    );
  }

  ///===================
  /// 组件
  ///===================

  Widget commonLayout() {
    return Column(
      children: [
        /// 归档状态提示条
        if (_isArchived) buildArchievdHint(),

        /// 标题输入框
        buildTitleInput(),

        /// 工具栏
        buildToolBar(),

        /// 分类和标签信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 显示分类
              if (_selectedCategoryId != null) buildCategory(),

              // 显示标签
              if (_selectedTags.isNotEmpty) buildTags(),
            ],
          ),
        ),

        /// 待办事项完成状态
        if (_isTodo) buildTodoState(),

        /// 富文本编辑器区域
        if (ScreenHelper.isDesktop())
          buildDesktopQuillEditor()
        else
          buildMobileQuillEditor(),
      ],
    );
  }

  List<Widget> buildActions() {
    // 获取分类数据
    final categoriesAsyncValue = ref.watch(noteCategoryViewModelProvider);
    // 获取标签数据
    final tagsAsyncValue = ref.watch(noteTagViewModelProvider);

    return [
      // 待办事项开关 - 只有非归档笔记才显示
      if (!_isReadOnly)
        IconButton(
          icon: Icon(_isTodo ? Icons.check_circle : Icons.circle_outlined),
          tooltip: '待办事项',
          onPressed: () {
            setState(() {
              _isTodo = !_isTodo;
              _isEdited = true;
            });
          },
        ),

      // 置顶开关 - 只有非归档笔记才显示
      if (!_isReadOnly)
        IconButton(
          icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
          tooltip: '置顶笔记',
          onPressed: () {
            setState(() {
              _isPinned = !_isPinned;
              _isEdited = true;
            });
          },
        ),

      // 更多选项菜单
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'category':
              _showCategoryDialog(categoriesAsyncValue.value ?? []);
              break;
            case 'tags':
              _showTagsDialog(tagsAsyncValue.value ?? []);
              break;
            case 'color':
              _showColorPicker();
              break;
            case 'archive':
              _toggleArchiveStatus();
              break;
            case 'delete':
              _confirmDeleteNote();
              break;
          }
        },
        itemBuilder: (context) => [
          // 分类选项 - 只有非归档笔记才显示
          if (!_isReadOnly)
            const PopupMenuItem<String>(
              value: 'category',
              child: ListTile(
                leading: Icon(Icons.category),
                title: Text('选择分类'),
                contentPadding: EdgeInsets.zero,
              ),
            ),

          // 标签选项 - 只有非归档笔记才显示
          if (!_isReadOnly)
            const PopupMenuItem<String>(
              value: 'tags',
              child: ListTile(
                leading: Icon(Icons.label),
                title: Text('管理标签'),
                contentPadding: EdgeInsets.zero,
              ),
            ),

          // 颜色选项 - 只有非归档笔记才显示
          if (!_isReadOnly)
            const PopupMenuItem<String>(
              value: 'color',
              child: ListTile(
                leading: Icon(Icons.color_lens),
                title: Text('设置颜色'),
                contentPadding: EdgeInsets.zero,
              ),
            ),

          // 归档/取消归档选项 - 只有笔记已保存（有ID）时才显示
          if (_currentNote != null && _currentNote!.id != null)
            PopupMenuItem<String>(
              value: 'archive',
              child: ListTile(
                leading: Icon(
                  _isArchived ? Icons.unarchive : Icons.archive,
                  color: Colors.blue,
                ),
                title: Text(
                  _isArchived ? '取消归档' : '归档笔记',
                  style: const TextStyle(color: Colors.blue),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),

          // 删除选项 - 只有笔记已保存（有ID）时才显示
          if (_currentNote != null && _currentNote!.id != null)
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除笔记', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    ];
  }

  // 确认删除笔记
  void _confirmDeleteNote() {
    // 如果当前没有笔记或笔记ID为空，则不执行删除操作
    if (_currentNote == null || _currentNote!.id == null) {
      ToastUtils.showToast('笔记尚未保存，无需删除');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除笔记'),
          content: const Text('确定要删除这个笔记吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                setState(() {
                  _isLoading = true;
                });

                try {
                  final notebookViewModel = ref.read(
                    notebookViewModelProvider.notifier,
                  );
                  await notebookViewModel.deleteNote(_currentNote!.id!);

                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });

                    commonExceptionDialog(context, '删除笔记失败', '删除笔记失败: $e');
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 切换笔记的归档状态
  void _toggleArchiveStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notebookViewModel = ref.read(notebookViewModelProvider.notifier);

      if (_isArchived) {
        // 取消归档
        if (_currentNote != null) {
          final updatedNote = await notebookViewModel.unarchiveNote(
            _currentNote!,
          );

          // 更新当前笔记引用
          setState(() {
            _currentNote = updatedNote;
            _isArchived = false; // 更新为取消归档状态
            _isReadOnly = false;
            _quillController.readOnly = false; // 允许编辑
            _isLoading = false;
            _isEdited = true; // 标记为已编辑，以便保存
          });
        }
      } else {
        // 归档笔记
        if (_currentNote != null) {
          final updatedNote = await notebookViewModel.archiveNote(
            _currentNote!,
          );

          // 更新当前笔记引用
          setState(() {
            _currentNote = updatedNote;
            _isArchived = true; // 更新为归档状态
            _isReadOnly = true;
            _quillController.readOnly = true; // 设置为只读
            _isLoading = false;
            _isEdited = true; // 标记为已编辑，以便保存
          });
        }
      }

      // 操作成功后显示提示
      if (mounted) {
        ToastUtils.showToast(_isArchived ? '笔记已归档' : '笔记已取消归档');
      }
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, '操作失败', '操作失败: $e');

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget buildArchievdHint() {
    return Container(
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.archive, color: Colors.amber),
          const SizedBox(width: 8),
          const Text(
            '此笔记已归档，处于只读状态',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _toggleArchiveStatus(),
            child: const Text('取消归档'),
          ),
        ],
      ),
    );
  }

  Widget buildTitleInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          hintText: '标题',
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        readOnly: _isReadOnly, // 归档笔记标题为只读
      ),
    );
  }

  Widget buildCategory() {
    // 获取分类数据
    final categoriesAsyncValue = ref.watch(noteCategoryViewModelProvider);

    return categoriesAsyncValue.when(
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => NoteCategory(name: '未知分类'),
        );
        return Container(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(category.name, style: TextStyle(color: Colors.white)),
            backgroundColor: category.getCategoryColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            onDeleted: _isReadOnly
                ? null
                : () {
                    // 归档笔记不允许删除分类
                    setState(() {
                      _selectedCategoryId = null;
                      _isEdited = true;
                    });
                  },
            deleteIcon: _isReadOnly
                ? null
                : const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Expanded buildTags() {
    // 获取标签数据
    final tagsAsyncValue = ref.watch(noteTagViewModelProvider);

    //  移动端可以显示5个，桌面端显示8个
    int showCount = ScreenHelper.isMobile() ? 5 : 8;

    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 最多显示标签数量
            ..._selectedTags.take(showCount).map((tag) {
              // 限制标签名称长度
              final displayName = tag.name.length > 5
                  ? '${tag.name.substring(0, 5)}...'
                  : tag.name;

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  label: Text(
                    displayName,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: tag.getTagColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  onDeleted: _isReadOnly
                      ? null
                      : () {
                          // 归档笔记不允许删除标签
                          setState(() {
                            _selectedTags.removeWhere((t) => t.id == tag.id);
                            _isEdited = true;
                          });
                        },
                  deleteIcon: _isReadOnly
                      ? null
                      : const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              );
            }),

            // 如果有更多标签，显示更多指示器
            if (_selectedTags.length > showCount)
              GestureDetector(
                onTap: _isReadOnly
                    ? null
                    : () => _showTagsDialog(tagsAsyncValue.value ?? []),
                child: Chip(
                  label: Text(
                    '+${_selectedTags.length - showCount}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),

            // 添加标签按钮 - 只有非归档笔记才显示
            if (!_isReadOnly)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showTagsDialog(tagsAsyncValue.value ?? []),
                tooltip: '管理标签',
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTodoState() {
    return CheckboxListTile(
      title: const Text('已完成'),
      value: _isCompleted,
      onChanged: _isReadOnly
          ? null
          : (value) {
              // 归档笔记不允许修改完成状态
              setState(() {
                _isCompleted = value ?? false;
                _isEdited = true;
              });
            },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget buildToolBar() {
    // 桌面端工具栏固定显示在顶部
    if (!_isReadOnly && ScreenHelper.isDesktop()) return commonQuillToolbar();

    // 移动端工具栏按钮和折叠区域 - 非桌面且非只读模式下显示
    if (!_isReadOnly && !ScreenHelper.isDesktop()) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "显示编辑工具"按钮
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ElevatedButton.icon(
                    onPressed: _toggleMobileToolbar,
                    icon: Icon(
                      _showMobileToolbar
                          ? Icons.keyboard_arrow_up
                          : Icons.format_shapes,
                    ),
                    label: Text(_showMobileToolbar ? '隐藏格式化工具' : '显示格式化工具'),
                    style: ElevatedButton.styleFrom(
                      // foregroundColor: Colors.white,
                      // backgroundColor: const Color.fromARGB(255, 161, 186, 206),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              ),
              NoteAudioRecorder(onAudioRecorded: _handleAudioRecorded),
              const SizedBox(width: 20),
            ],
          ),

          // 可折叠的工具栏区域
          // if (_showMobileToolbar) const SizedBox(height: 8),
          // if (_showMobileToolbar) commonQuillToolbar(),
          if (_showMobileToolbar)
            Container(
              height: 100, // 固定高度，可滚动
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(child: commonQuillToolbar()),
            ),
        ],
      );
    }

    // 正常应该不会到这里来
    return const SizedBox.shrink();
  }

  Container commonQuillToolbar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          embedButtons: FlutterQuillEmbeds.toolbarButtons(),
          // 这几个默认是false所以改为true，其他未列出来的都是默认true
          showSmallButton: true,
          showLineHeightButton: true,
          showAlignmentButtons: true,
          showDirection: true,
          showClipboardCut: true,
          showClipboardCopy: true,
          showClipboardPaste: true,
        ),
      ),
    );
  }

  // 桌面端编辑器直接Expanded填充满剩下的区域即可
  Widget buildDesktopQuillEditor() {
    return Expanded(
      child: Column(
        children: [
          // 音频列表
          if (_currentNote != null)
            NoteAudioList(
              audioList: _currentNote!.mediaList,
              onDelete: _handleDeleteMedia,
              isReadOnly: _isReadOnly,
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: _isReadOnly
                      ? Colors.grey.shade50
                      : (_selectedColor != null
                            ? Color(_selectedColor!)
                            : null),
                ),
                child: commonQuillEditor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端设定一个固定高度的编辑区域，且父组件设置为可滚动，避免键盘弹出后编辑区域太小
  // 因为有固定高度，所以不能使用Expanded，否则会溢出
  Widget buildMobileQuillEditor() {
    return Column(
      children: [
        // 音频列表
        if (_currentNote != null)
          NoteAudioList(
            audioList: _currentNote!.mediaList,
            onDelete: _handleDeleteMedia,
            isReadOnly: _isReadOnly,
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: _isReadOnly
                  ? Colors.grey.shade50
                  : (_selectedColor != null ? Color(_selectedColor!) : null),
            ),
            child: SizedBox(height: 0.75.sh, child: commonQuillEditor()),
          ),
        ),
      ],
    );
  }

  QuillEditor commonQuillEditor() {
    return QuillEditor.basic(
      controller: _quillController,
      focusNode: _editorFocusNode,
      config: QuillEditorConfig(
        placeholder: '在此输入笔记内容...',
        embedBuilders: kIsWeb
            ? FlutterQuillEmbeds.editorWebBuilders()
            : FlutterQuillEmbeds.editorBuilders(),
        autoFocus: true,
        showCursor: true,
        expands: ScreenHelper.isDesktop() ? true : false,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  ///===================
  /// 分类和标签弹窗相关
  ///===================

  // 显示分类选择对话框
  void _showCategoryDialog(List<NoteCategory> categories) {
    // 函数内使用buildContext而不是传递的context
    final BuildContext dialogContext = context;

    showDialog(
      context: dialogContext,
      builder: (context) {
        return CommonDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择分类',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: categories.isEmpty
                    ? const Center(child: Text('暂无分类，请点击"新建分类"按钮创建'))
                    : ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return ListTile(
                            title: Text(category.name),
                            leading: CircleAvatar(
                              backgroundColor: category.getCategoryColor(),
                              child: const Icon(
                                Icons.category,
                                color: Colors.white,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteCategory(category),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = category.id;
                                _isEdited = true;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => _showCreateCategoryDialog(),
                    child: const Text('新建分类'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示创建分类对话框
  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CommonDialog(
          height: MediaQuery.of(context).size.height * 0.8,
          child: CreateColorItemDialog(
            title: '新建分类',
            itemName: '分类',
            maxLength: 6,
            onSubmit: (name, color) async {
              try {
                final categoryViewModel = ref.read(
                  noteCategoryViewModelProvider.notifier,
                );
                final category = await categoryViewModel.createCategory(
                  name,
                  color: color,
                );

                if (mounted) {
                  final selectedCategoryId = category.id;
                  await categoryViewModel.refreshCategories();

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  setState(() {
                    _selectedCategoryId = selectedCategoryId;
                    _isEdited = true;
                  });

                  // 使用Navigator.of(context)会导致错误，因为可能已经不在上下文中
                  // 改为用返回值来处理
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                }
              } catch (e) {
                if (mounted) {
                  commonExceptionDialog(context, '创建笔记分类失败', '创建笔记分类失败: $e');
                }
              }
            },
          ),
        );
      },
    );
  }

  // 确认删除分类
  void _confirmDeleteCategory(NoteCategory category) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除分类'),
          content: Text('确定要删除分类"${category.name}"吗？笔记将会被移除分类但不会被删除。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final categoryViewModel = ref.read(
                    noteCategoryViewModelProvider.notifier,
                  );
                  await categoryViewModel.deleteCategory(category.id!);

                  // 如果当前笔记使用了这个分类，清除它
                  if (_selectedCategoryId == category.id) {
                    setState(() {
                      _selectedCategoryId = null;
                      _isEdited = true;
                    });
                  }

                  // 刷新分类列表
                  await categoryViewModel.refreshCategories();

                  // 关闭确认对话框
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);

                    // 获取最新的分类列表
                    final categories =
                        ref.read(noteCategoryViewModelProvider).value ?? [];

                    // 如果已经不在导航堆栈中，不要尝试关闭
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                      // 重新打开分类选择对话框
                      _showCategoryDialog(categories);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    commonExceptionDialog(context, '删除笔记分类失败', '删除笔记分类失败: $e');
                  }
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 显示标签管理对话框
  void _showTagsDialog(List<NoteTag> allTags) {
    // 创建一个临时的选中标签列表
    final tempSelectedTags = List<NoteTag>.from(_selectedTags);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CommonDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '管理标签',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('新建标签'),
                        onPressed: () {
                          _showCreateTagDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '选择标签',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: allTags.isEmpty
                        ? const Center(child: Text('暂无标签，请点击"新建标签"按钮创建'))
                        : ListView.builder(
                            itemCount: allTags.length,
                            itemBuilder: (context, index) {
                              final tag = allTags[index];
                              final isSelected = tempSelectedTags.any(
                                (t) => t.id == tag.id,
                              );
                              return CheckboxListTile(
                                title: Text(tag.name),
                                value: isSelected,
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (tag.color != null)
                                      CircleAvatar(
                                        backgroundColor: tag.getTagColor(),
                                        radius: 12,
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      tooltip: '删除标签',
                                      onPressed: () {
                                        _confirmDeleteTag(
                                          tag,
                                          setDialogState,
                                          tempSelectedTags,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      if (!tempSelectedTags.any(
                                        (t) => t.id == tag.id,
                                      )) {
                                        tempSelectedTags.add(tag);
                                      }
                                    } else {
                                      tempSelectedTags.removeWhere(
                                        (t) => t.id == tag.id,
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTags = List.from(tempSelectedTags);
                            _isEdited = true;
                          });
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 显示创建标签对话框
  void _showCreateTagDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CommonDialog(
          child: CreateColorItemDialog(
            title: '新建标签',
            itemName: '标签',
            maxLength: 10,
            onSubmit: (name, color) async {
              try {
                final tagViewModel = ref.read(
                  noteTagViewModelProvider.notifier,
                );
                await tagViewModel.createTag(name, color: color);

                if (mounted) {
                  await tagViewModel.refreshTags();

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  // 使用Navigator.canPop检查是否可以安全地弹出
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }

                  final allTags =
                      ref.read(noteTagViewModelProvider).value ?? [];
                  _showTagsDialog(allTags);
                }
              } catch (e) {
                if (mounted) {
                  commonExceptionDialog(context, '创建笔记标签失败', '创建笔记标签失败: $e');
                }
              }
            },
          ),
        );
      },
    );
  }

  // 确认删除标签
  void _confirmDeleteTag(
    NoteTag tag,
    StateSetter setDialogState,
    List<NoteTag> tempSelectedTags,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除标签'),
          content: Text('确定要删除标签"${tag.name}"吗？所有使用此标签的笔记将会移除该标签。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final tagViewModel = ref.read(
                    noteTagViewModelProvider.notifier,
                  );
                  await tagViewModel.deleteTag(tag.id!);

                  // 从临时选中列表中移除
                  setDialogState(() {
                    tempSelectedTags.removeWhere((t) => t.id == tag.id);
                  });

                  // 从实际选中列表中移除
                  setState(() {
                    _selectedTags.removeWhere((t) => t.id == tag.id);
                    _isEdited = true;
                  });

                  // 刷新标签列表
                  await tagViewModel.refreshTags();

                  // 关闭确认对话框
                  if (context.mounted) {
                    Navigator.pop(context);

                    // 获取最新的标签列表
                    final allTags =
                        ref.read(noteTagViewModelProvider).value ?? [];

                    // 关闭原标签管理对话框
                    Navigator.pop(context);

                    // 重新打开标签管理对话框
                    _showTagsDialog(allTags);
                  }
                } catch (e) {
                  if (context.mounted) {
                    commonExceptionDialog(context, '删除笔记标签失败', '删除笔记标签失败: $e');
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 显示颜色选择器
  void _showColorPicker() {
    // 当前颜色或默认颜色
    Color pickerColor = _selectedColor != null
        ? Color(_selectedColor!)
        : Colors.blue;
    bool showAdvancedPicker = false;

    buildDefaultColorPicker(BuildContext dialogContext) {
      return SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 无颜色选项
            GestureDetector(
              onTap: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _selectedColor = null;
                  _isEdited = true;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.format_color_reset)),
              ),
            ),

            // 颜色选项
            ...Colors.primaries.map((color) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedColor = color.toARGB32();
                    _isEdited = true;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),

            // 灰度颜色
            ...List.generate(3, (index) {
              final color = Colors.grey[(index + 2) * 100];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedColor = color?.toARGB32();
                    _isEdited = true;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    buildAdvancedColorPicker() {
      return SingleChildScrollView(
        child: ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: (Color color) {
            pickerColor = color;
          },
          pickerAreaHeightPercent: 0.7,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
          portraitOnly: true,
          enableAlpha: true,
          labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
          pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
          hexInputBar: true,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CommonDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '选择笔记颜色',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 切换基本/高级选择器按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            showAdvancedPicker = !showAdvancedPicker;
                          });
                        },
                        icon: Icon(
                          showAdvancedPicker ? Icons.palette : Icons.color_lens,
                        ),
                        label: Text(showAdvancedPicker ? '预设颜色' : '高级选择'),
                      ),
                    ],
                  ),

                  Expanded(
                    child: showAdvancedPicker
                        ? buildAdvancedColorPicker()
                        : buildDefaultColorPicker(dialogContext),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('取消'),
                      ),
                      if (showAdvancedPicker)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            setState(() {
                              _selectedColor = pickerColor.toARGB32();
                              _isEdited = true;
                            });
                          },
                          child: const Text('确定'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 处理录制的音频
  Future<void> _handleAudioRecorded(File audioFile) async {
    try {
      if (_currentNote == null) {
        // 如果是新笔记，先保存笔记
        await _saveNote(silent: true);
      }

      if (_currentNote != null) {
        final notebookViewModel = ref.read(notebookViewModelProvider.notifier);

        // 将音频文件添加到笔记
        await notebookViewModel.addMediaToNote(
          _currentNote!,
          audioFile,
          'audio',
        );

        setState(() {
          _isEdited = true;
        });

        if (mounted) {
          ToastUtils.showToast('录音已保存');
        }
      }
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, '保存录音失败', '保存录音失败: $e');
      }
    }
  }

  // 处理删除媒体文件
  Future<void> _handleDeleteMedia(NoteMedia media) async {
    try {
      if (_currentNote != null) {
        final notebookViewModel = ref.read(notebookViewModelProvider.notifier);
        await notebookViewModel.deleteNoteMedia(_currentNote!, media.id!);

        setState(() {
          _isEdited = true;
        });

        if (mounted) {
          ToastUtils.showToast('删除成功');
        }
      }
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, '删除媒体文件失败', '删除媒体文件失败: $e');
      }
    }
  }
}
