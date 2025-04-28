import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../../../common/components/toast_utils.dart';
import '../../../../common/components/tool_widget.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../models/brief_ai_tools/chat_completions/bigmodel_file_manage.dart';
import '../../../../services/bigmodel_file_service.dart';
import '../../../../services/cus_get_storage.dart';
import '../../_chat_components/text_selection_dialog.dart';

class FileUploadPage extends StatefulWidget {
  /// 文件内容分析回调函数
  final Function(String fileContent, String fileName)? onFileAnalyze;

  const FileUploadPage({super.key, this.onFileAnalyze});

  @override
  State createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  PlatformFile? _selectedFile;
  double _uploadProgress = 0.0;
  String _uploadStatus = '未选择文件';
  final TextEditingController _apiKeyController = TextEditingController();
  List<BigmodelGetFilesResult> _fileList = [];

  // 获取到的文件内容数据
  String currentFileContent = "";
  // 当前正在查看的文件名
  String currentFileName = "";

  // 当前选中的文件
  BigmodelGetFilesResult? _selectedListFile;
  // 正在加载文件内容
  bool _isLoadingFileContent = false;

  // 添加一个控制API Key是否显示的标志
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    getApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  getApiKey() {
    setState(() {
      _apiKeyController.text = MyGetStorage().getBigmodelApiKey() ?? '';
    });

    if (_apiKeyController.text.trim().isNotEmpty) {
      _getFileList();
    }
  }

  // 选择文件
  Future<void> _pickFile() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _uploadStatus = '请先输入API Key';
      });
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // 可以选择任何类型文件
        allowMultiple: false, // 单选
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _uploadStatus = '已选择: ${_selectedFile!.name}';
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '选择文件出错: $e';
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      setState(() => _uploadStatus = '请先选择文件');
      return;
    }

    setState(() {
      _uploadStatus = '上传中...';
      _uploadProgress = 0;
    });

    final closeToast = ToastUtils.showLoading('【文件上传中...】');

    try {
      BigmodelFileUploadResult response =
          await BigmodelFileService.uploadFilesToBigmodel(
            File(_selectedFile!.path!),
            "file-extract",
          );

      setState(() {
        _uploadStatus = '上传成功';
        _uploadProgress = 1;
      });

      closeToast();
      ToastUtils.showSuccess('文件上传成功\n文件ID:${response.id}');

      // 上传成功后刷新文件列表
      _getFileList();
    } on DioException catch (e) {
      closeToast();
      setState(() {
        _uploadStatus = '上传失败: ${e.response?.statusCode ?? e.message}';
      });

      if (!mounted) return;
      commonExceptionDialog(context, '文件上传失败', e.toString());
    } catch (e) {
      closeToast();
      setState(() {
        _uploadStatus = '发生错误: $e';
      });

      if (!mounted) return;
      commonExceptionDialog(context, '文件上传失败', e.toString());
    }
  }

  Future<void> _deleteFile(String fileId) async {
    final closeToast = ToastUtils.showLoading('【文件删除中...】');

    try {
      BigmodelDeleteFilesResult response =
          await BigmodelFileService.deleteFileFromBigmodel(fileId);

      closeToast();
      ToastUtils.showSuccess('文件删除成功\n文件ID:${response.id} ');

      // 如果删除的是当前选中的文件，清除选中状态
      if (_selectedListFile != null && _selectedListFile!.id == fileId) {
        setState(() {
          _selectedListFile = null;
        });
      }

      await _getFileList();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '文件删除失败', e.toString());
    }
  }

  Future<void> _getFileList() async {
    final closeToast = ToastUtils.showLoading('【获取文件列表...】');

    try {
      List<BigmodelGetFilesResult> response =
          await BigmodelFileService.getFileListFromBigmodel("file-extract");

      setState(() {
        _fileList = response;
        // 文件列表更新后，检查选中的文件是否还存在
        if (_selectedListFile != null) {
          final stillExists = _fileList.any(
            (file) => file.id == _selectedListFile!.id,
          );
          if (!stillExists) {
            _selectedListFile = null;
          }
        }
      });

      closeToast();
    } catch (e) {
      closeToast();
      if (!mounted) return;
      commonExceptionDialog(context, '获取文件列表失败', e.toString());
    }
  }

  Future<void> _getFileData(String fileId, String fileName) async {
    final closeToast = ToastUtils.showLoading('【获取文件内容...】');

    try {
      BigmodelExtractFileResult response =
          await BigmodelFileService.getFileDataFromBigmodelFile(fileId);

      setState(() {
        currentFileContent = response.content;
        currentFileName = fileName;
      });

      closeToast();

      // 显示文件内容弹窗
      if (!mounted) return;
      _showFileContentDialog();
    } catch (e) {
      closeToast();
      if (!mounted) return;
      commonExceptionDialog(context, '获取文件内容失败', e.toString());
    }
  }

  // 获取文件内容并分析（返回文件内容给调用者）
  Future<void> _analyzeSelectedFile() async {
    if (_selectedListFile == null || _isLoadingFileContent) return;

    setState(() {
      _isLoadingFileContent = true;
    });

    final closeToast = ToastUtils.showLoading('【获取文件内容...】');

    try {
      BigmodelExtractFileResult response =
          await BigmodelFileService.getFileDataFromBigmodelFile(
            _selectedListFile!.id,
          );

      closeToast();

      // 调用回调函数，传递文件内容和文件名
      if (widget.onFileAnalyze != null) {
        widget.onFileAnalyze!(response.content, _selectedListFile!.filename);
      }

      // 关闭当前页面
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      closeToast();
      setState(() {
        _isLoadingFileContent = false;
      });

      if (!mounted) return;
      commonExceptionDialog(context, '获取文件内容失败', e.toString());
    }
  }

  // 选择文件（单选）
  void _toggleFileSelection(BigmodelGetFilesResult file) {
    setState(() {
      if (_selectedListFile?.id == file.id) {
        // 如果点击的是已选中的文件，取消选择
        _selectedListFile = null;
      } else {
        // 否则选中当前文件
        _selectedListFile = file;
      }
    });
  }

  // 显示文件内容的全屏弹窗
  _showFileContentDialog() async {
    showDialog(
      context: context,
      builder:
          (context) => TextSelectionDialog(
            title: currentFileName,
            text: currentFileContent,
          ),
    );
  }

  // 预览文件（可选）
  Future<void> _previewFile() async {
    if (_selectedFile == null) return;

    try {
      // 如果是本地文件，直接打开
      if (_selectedFile!.path != null) {
        await OpenFile.open(_selectedFile!.path);
      } else {
        // 如果是web平台或其他情况，可能需要下载临时文件
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${_selectedFile!.name}');
        await tempFile.writeAsBytes(_selectedFile!.bytes!);
        await OpenFile.open(tempFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '无法打开文件', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ScreenHelper.isDesktop();

    return Scaffold(
      appBar: AppBar(
        title: Text('智谱开放平台文件管理'),
        elevation: isDesktop ? 0 : null,
        backgroundColor:
            isDesktop
                ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : null,
        actions: [
          if (_selectedListFile != null)
            TextButton.icon(
              onPressed: _analyzeSelectedFile,
              icon: Icon(Icons.analytics),
              label: Text('分析此文件'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: Container(
        color: isDesktop ? Theme.of(context).colorScheme.surface : null,
        child: SingleChildScrollView(
          padding: ScreenHelper.adaptPadding(const EdgeInsets.all(4.0)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // maxWidth: isDesktop ? 1200 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildApiKeySection(),
                  SizedBox(height: ScreenHelper.adaptHeight(24)),
                  if (isDesktop)
                    _buildDesktopLayout()
                  else
                    _buildMobileLayout(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧上传和操作区域
        Expanded(flex: 2, child: _buildUploadSection()),
        SizedBox(width: ScreenHelper.adaptWidth(24)),
        // 右侧文件列表区域
        Expanded(flex: 3, child: _buildFileListSection()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildUploadSection(),
        SizedBox(height: ScreenHelper.adaptHeight(24)),
        _buildFileListSection(),
      ],
    );
  }

  Widget _buildApiKeySection() {
    return Card(
      elevation: ScreenHelper.isDesktop() ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ScreenHelper.adaptPadding(const EdgeInsets.all(8.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'API Key 设置',
                  style: TextStyle(
                    fontSize: ScreenHelper.getFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (ScreenHelper.isMobile()) _buildSaveKeyButton(),
              ],
            ),
            SizedBox(height: ScreenHelper.adaptHeight(16)),
            Row(
              children: [
                _buildApiKeyInput(),
                SizedBox(width: ScreenHelper.adaptWidth(8)),
                if (!ScreenHelper.isMobile()) _buildSaveKeyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyInput() {
    return Expanded(
      child: TextField(
        controller: _apiKeyController,
        obscureText: _obscureApiKey,
        decoration: InputDecoration(
          labelText: '请输入 API Key',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: Icon(Icons.vpn_key),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureApiKey ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
            ),
            onPressed: () {
              setState(() {
                _obscureApiKey = !_obscureApiKey;
              });
            },
            tooltip: _obscureApiKey ? '显示 API Key' : '隐藏 API Key',
          ),
          contentPadding: ScreenHelper.adaptPadding(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveKeyButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        await MyGetStorage().setBigmodelApiKey(_apiKeyController.text);
        getApiKey();
        ToastUtils.showSuccess('API Key 已保存');
      },
      icon: Icon(Icons.save),
      label: Text('保存'),
      style: ElevatedButton.styleFrom(
        padding: ScreenHelper.adaptPadding(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: ScreenHelper.isDesktop() ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ScreenHelper.adaptPadding(const EdgeInsets.all(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  '文件上传',
                  style: TextStyle(
                    fontSize: ScreenHelper.getFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenHelper.adaptHeight(16)),

            if (_selectedFile != null) ...[
              Container(
                // padding: ScreenHelper.adaptPadding(const EdgeInsets.all(4)),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading:
                      ScreenHelper.isDesktop()
                          ? Icon(
                            Icons.insert_drive_file,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          )
                          : null,
                  title: Text(
                    _selectedFile!.name,
                    style: TextStyle(fontSize: ScreenHelper.getFontSize(14)),
                  ),
                  subtitle: Text(
                    '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                    style: TextStyle(fontSize: ScreenHelper.getFontSize(12)),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.preview),
                    onPressed: _previewFile,
                    tooltip: '预览文件',
                  ),
                ),
              ),
              SizedBox(height: ScreenHelper.adaptHeight(16)),
            ],

            LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: ScreenHelper.adaptHeight(6),
              borderRadius: BorderRadius.circular(3),
            ),
            SizedBox(height: ScreenHelper.adaptHeight(8)),
            Text(
              _uploadStatus,
              style: TextStyle(
                fontSize: ScreenHelper.getFontSize(12),
                color:
                    _uploadProgress == 1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: ScreenHelper.adaptHeight(16)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: _apiKeyController.text.isEmpty ? null : _pickFile,
                  icon: Icon(Icons.upload_file),
                  tooltip: "选择文件",
                ),
                IconButton(
                  onPressed: _selectedFile == null ? null : _uploadFile,
                  icon: Icon(Icons.cloud_upload),
                  tooltip: "上传文件",
                ),
                IconButton(
                  onPressed:
                      _apiKeyController.text.isEmpty ? null : _getFileList,
                  icon: Icon(Icons.refresh),
                  tooltip: "刷新文件列表",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListSection() {
    return Card(
      elevation: ScreenHelper.isDesktop() ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: ScreenHelper.adaptPadding(const EdgeInsets.all(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '文件列表',
                      style: TextStyle(
                        fontSize: ScreenHelper.getFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: ScreenHelper.adaptPadding(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '共 ${_fileList.length} 个文件',
                    style: TextStyle(
                      fontSize: ScreenHelper.getFontSize(12),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenHelper.adaptHeight(16)),
            if (_fileList.isEmpty)
              Center(
                child: Padding(
                  padding: ScreenHelper.adaptPadding(
                    const EdgeInsets.all(24.0),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '暂无文件',
                        style: TextStyle(
                          fontSize: ScreenHelper.getFontSize(14),
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _fileList.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final file = _fileList[index];
                  final isSelected = _selectedListFile?.id == file.id;

                  return Material(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.3)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: () => _toggleFileSelection(file),
                      borderRadius: BorderRadius.circular(4),
                      child: ListTile(
                        contentPadding: ScreenHelper.adaptPadding(
                          const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                        ),
                        leading: Stack(
                          children: [
                            Icon(
                              _getFileIcon(file.filename),
                              color: Theme.of(context).colorScheme.primary,
                              size: (ScreenHelper.isMobile()) ? 20 : 36,
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.check,
                                    size: ScreenHelper.isMobile() ? 12 : 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          file.filename,
                          style: TextStyle(
                            fontSize: ScreenHelper.getFontSize(14),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID: ${file.id}',
                              style: TextStyle(
                                fontSize: ScreenHelper.getFontSize(11),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.description, color: Colors.blue),
                              onPressed:
                                  () => _getFileData(file.id, file.filename),
                              tooltip: '查看文件内容',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFile(file.id),
                              tooltip: '删除文件',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 根据文件名获取对应的图标
  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
