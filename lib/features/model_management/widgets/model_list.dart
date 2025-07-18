import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/toast_utils.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../../core/entities/cus_llm_model.dart';
import '../../../shared/constants/constant_llm_enum.dart';
import '../../../core/storage/db_helper.dart';
import '../../../core/utils/file_picker_utils.dart';
import '../../../core/utils/screen_helper.dart';
import '../../../core/utils/simple_tools.dart';
import '../../../shared/services/model_manager_service.dart';
import '../../branch_chat/presentation/pages/add_model_page.dart';

class ModelList extends StatefulWidget {
  const ModelList({super.key});

  @override
  State<ModelList> createState() => _ModelListState();
}

class _ModelListState extends State<ModelList> {
  final DBHelper _dbHelper = DBHelper();
  List<CusLLMSpec> _models = [];
  bool _isLoading = true;
  bool _isImporting = false;
  int _sortColumnIndex = 0; // 当前排序的列索引
  bool _sortAscending = true; // 是否升序

  // 搜索相关变量
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadModels();

    // 添加搜索监听
    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 加载模型列表
  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await _dbHelper.queryCusLLMSpecList();
      setState(() => _models = models);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 删除模型
  Future<void> _deleteModel(CusLLMSpec model) async {
    final models = await _dbHelper.queryCusLLMSpecList(
      modelType: model.modelType,
    );
    if (models.length <= 1) {
      ToastUtils.showError("无其他同类模型，不可删除");
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除模型 ${model.name} 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await ModelManagerService.deleteUserModel(model.cusLlmSpecId);
      if (mounted) {
        _loadModels();
      }
    }
  }

  // 清除所有自行导入的模型
  Future<void> _clearAllModels(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认清除'),
            content: const Text('确定要清除所有自行导入的模型吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await ModelManagerService.clearUserModels();

      // 2025-04-15 清除全部用户模型后，重新加载预设模型，避免无可用模型
      await ModelManagerService.initBuiltinModels();
      if (mounted) {
        _loadModels();
      }
    }
  }

  // 从JSON文件导入模型
  Future<void> _importFromJson() async {
    File? file = await FilePickerUtils.pickAndSaveFile(
      fileType: CusFileType.custom,
      allowedExtensions: ['json'],
      overwrite: true,
    );

    if (file == null) return;

    setState(() => _isImporting = true);
    try {
      final jsonStr = await file.readAsString();
      final jsonList = json.decode(jsonStr) as List;

      // 验证模型配置
      for (final item in jsonList) {
        if (!ModelManagerService.validateModelConfig(item)) {
          throw '模型配置格式错误';
        }
      }

      // 默认导入的json文件中是没有模型规格编号的，而该类为必要属性，所以需要先生成一个
      for (final item in jsonList) {
        item['cusLlmSpecId'] = const Uuid().v4();
      }

      // 转换为模型列表
      var models = jsonList.map((json) => CusLLMSpec.fromJson(json)).toList();

      // 设置ID和时间
      models =
          models.map((e) {
            // e.name =
            //     !(e.isFree ?? false)
            //         ? '【收费】${e.name ?? capitalizeWords(e.model)}'
            //         : (e.name ?? capitalizeWords(e.model));
            // 2025-04-26 感觉这个是否收费栏位没什么必要
            e.name = e.name ?? capitalizeWords(e.model);
            e.gmtCreate = DateTime.now();
            e.isBuiltin = false; // 用户导入的模型
            return e;
          }).toList();

      // 查询是否存在同名模型
      List<CusLLMSpec> duplicateModels = [];
      final existModels = await _dbHelper.queryCusLLMSpecList();
      for (final model in models) {
        if (existModels.any(
          (e) => e.platform == model.platform && e.model == model.model,
        )) {
          duplicateModels.add(model);
        } else {
          await _dbHelper.saveCusLLMSpecs([model]);
        }
      }

      if (!mounted) return;
      commonHintDialog(context, '导入成功', """成功导入 ${models.length} 个模型，
          \n其中 ${duplicateModels.length} 个模型名称已存在，
          \n实际导入 ${models.length - duplicateModels.length} 个模型。""");

      _loadModels();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "导入失败", e.toString());
      _loadModels();
    } finally {
      setState(() => _isImporting = false);
    }
  }

  /// 排序方法
  /// [getField] 获取排序的值
  /// [columnIndex] 列索引
  /// [ascending] 是否升序
  void _sort<T>(
    Comparable<T> Function(CusLLMSpec d) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _models.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  // 过滤模型列表
  List<CusLLMSpec> get _filteredModels {
    if (_searchKeyword.isEmpty) return _models;

    return _models.where((model) {
      return (model.name?.toLowerCase().contains(_searchKeyword) ?? false) ||
          model.model.toLowerCase().contains(_searchKeyword) ||
          (CP_NAME_MAP[model.platform]?.toLowerCase().contains(
                _searchKeyword,
              ) ??
              false) ||
          (MT_NAME_MAP[model.modelType]?.toLowerCase().contains(
                _searchKeyword,
              ) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 根据平台类型选择不同的UI
    return ScreenHelper.isDesktop()
        ? _buildDesktopLayout()
        : _buildMobileLayout();
  }

  // 桌面端布局
  Widget _buildDesktopLayout() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 2,
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              child: _buildSimpleTable(),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局
  Widget _buildMobileLayout() {
    return Column(
      children: [_buildHeader(), Expanded(child: _buildSimpleTable())],
    );
  }

  // 表格标题行
  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              // child: Text(
              //   '共${_models.length}个模型${_searchKeyword.isNotEmpty ? "(筛选${_filteredModels.length}个)" : ""}',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "共${_models.length}个模型",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                          _searchKeyword.isNotEmpty
                              ? "(${_filteredModels.length})"
                              : "",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                final result = await Navigator.push<CusLLMSpec>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddModelPage()),
                );

                if (result != null) {
                  _loadModels();
                }
              },
              tooltip: '添加新模型',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _clearAllModels(context),
              tooltip: '清除所有自定义模型，并恢复内置模型',
            ),
            if (_isImporting)
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () => _importFromJson(),
                tooltip: '导入模型配置json',
              ),
          ],
        ),

        // 搜索框
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: '搜索模型（名称、平台、类型）',
              prefixIcon: Icon(Icons.search),
              suffixIcon:
                  _searchKeyword.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  void showModelInfo(BuildContext context, CusLLMSpec model) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 0.7.sh,
          padding: EdgeInsets.only(top: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        model.name ?? model.model,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('关闭'),
                      onPressed: () {
                        Navigator.pop(context);
                        unfocusHandle();
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 2, thickness: 2),
              Expanded(child: _infoRows(model)),
            ],
          ),
        );
      },
    );
  }

  // 信息项显示行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // 简单的表格实现，避免DataTable的约束问题
  Widget _buildSimpleTable() {
    final filteredModels = _filteredModels;

    return Column(
      children: [
        // 表头
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              _buildHeaderCell(
                '平台',
                flex: 2,
                onTap: () {
                  _sort<String>(
                    (d) => CP_NAME_MAP[d.platform] ?? '',
                    0,
                    _sortColumnIndex == 0 ? !_sortAscending : true,
                  );
                },
              ),
              _buildHeaderCell(
                '模型',
                flex: 5,
                onTap: () {
                  _sort<String>(
                    (d) => d.model,
                    1,
                    _sortColumnIndex == 1 ? !_sortAscending : true,
                  );
                },
              ),
              _buildHeaderCell(
                '类型',
                flex: 2,
                onTap: () {
                  _sort<String>(
                    (d) => d.modelType.name,
                    2,
                    _sortColumnIndex == 2 ? !_sortAscending : true,
                  );
                },
              ),
              _buildHeaderCell('操作', flex: 1, onTap: null),
            ],
          ),
        ),

        // 表格内容，使用ListView可以垂直滚动
        Expanded(
          child:
              filteredModels.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '没有找到匹配的模型',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: filteredModels.length,
                    itemBuilder: (context, index) {
                      final model = filteredModels[index];
                      final isEven = index.isEven;

                      return GestureDetector(
                        // 移动端长按显示详情，桌面端右键显示菜单
                        onLongPress:
                            ScreenHelper.isMobile()
                                ? () => showModelInfo(context, model)
                                : null,
                        onSecondaryTapDown:
                            ScreenHelper.isDesktop()
                                ? (details) => _showContextMenu(
                                  context,
                                  model,
                                  details.globalPosition,
                                )
                                : null,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                isEven
                                    ? Colors.grey.withValues(alpha: 0.05)
                                    : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          padding: EdgeInsets.all(8),
                          child: _buildItemRow(model),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildItemRow(CusLLMSpec model) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(CP_NAME_MAP[model.platform] ?? '')),
        Expanded(
          flex: 5,
          child: Tooltip(
            message: model.model,
            child: Text(
              model.model,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        Expanded(flex: 2, child: Text(MT_NAME_MAP[model.modelType] ?? '-')),
        Expanded(
          flex: 1,
          child: Center(
            child:
                model.isBuiltin
                    // ? const Text('内置', style: TextStyle(color: Colors.grey))
                    ? TextButton(
                      onPressed: () => _deleteModel(model),
                      style: TextButton.styleFrom(
                        // 将最小尺寸设置为零
                        minimumSize: Size.zero,
                        // 将内边距设置为零
                        padding: EdgeInsets.zero,
                        // 缩小点击目标区域
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('内置', style: TextStyle(color: Colors.grey)),
                    )
                    : IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _deleteModel(model),
                      tooltip: '删除模型',
                    ),
          ),
        ),
      ],
    );
  }

  // 构建表头单元格
  Widget _buildHeaderCell(
    String text, {
    required int flex,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (onTap != null) ...[
              SizedBox(width: 4),
              Icon(
                _sortColumnIndex == _getColumnIndex(text)
                    ? (_sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 获取列索引
  int _getColumnIndex(String columnName) {
    switch (columnName) {
      case '平台':
        return 0;
      case '模型':
        return 1;
      case '类型':
        return 2;
      default:
        return -1;
    }
  }

  // 在桌面端显示右键上下文菜单
  void _showContextMenu(
    BuildContext context,
    CusLLMSpec model,
    Offset position,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // 查看详情选项
    items.add(
      PopupMenuItem<String>(
        value: 'info',
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 18),
            SizedBox(width: 8),
            Text('查看详情'),
          ],
        ),
      ),
    );

    // 删除选项（仅非内置模型显示）
    if (!model.isBuiltin) {
      items.add(
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('删除模型'),
            ],
          ),
        ),
      );
    }

    // 显示菜单并处理选择结果
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'info':
          _showModelInfoDialog(model);
          break;
        case 'delete':
          _deleteModel(model);
          break;
      }
    });
  }

  // 在桌面端使用对话框显示模型详情
  void _showModelInfoDialog(CusLLMSpec model) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 600,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        model.name ?? model.model,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(height: 24, thickness: 1),
                  Expanded(child: _infoRows(model)),
                ],
              ),
            ),
          ),
    );
  }

  Widget _infoRows(CusLLMSpec model) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('部署平台', CP_NAME_MAP[model.platform] ?? ''),
          _buildInfoRow('模型代号', model.model),
          if (model.baseUrl != null) _buildInfoRow('请求地址', model.baseUrl!),
          if (model.apiKey != null) _buildInfoRow('API Key', model.apiKey!),
          _buildInfoRow('模型名称', model.name ?? '-'),
          _buildInfoRow('模型类型', MT_NAME_MAP[model.modelType] ?? '-'),
          _buildInfoRow('是否免费', (model.isFree ?? false) ? '是' : '否'),
          _buildInfoRow('是否内置', model.isBuiltin ? '是' : '否'),
          _buildInfoRow(
            '创建日期',
            model.gmtCreate?.toString().substring(0, 10) ?? '-',
          ),
          _buildInfoRow('模型描述', model.description ?? '-'),
        ],
      ),
    );
  }
}
