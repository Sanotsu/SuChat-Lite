import 'dart:io';

import 'package:doc_text/doc_text.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;

import '../../../../shared/widgets/sounds_message_button/button_widget/sounds_message_button.dart';
import '../../../../shared/widgets/sounds_message_button/utils/sounds_recorder_controller.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/utils/document_parser.dart';
import '../../../../core/utils/file_picker_utils.dart';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../data/datasources/xunfei_apis.dart';
import '../pages/file_upload_to_bigmodel_page.dart';

// 定义消息数据类
class MessageData {
  final String text;
  final List<File>? images;
  final File? audio;
  // 本地可用获取文档文件
  final File? file;
  // 云端只能获取文档的文件名
  final String? cloudFileName;
  // 本地云端都使用同一个文档内容变量，两者不会同时存在
  final String? fileContent;
  final List<File>? videos;
  // 可以根据需要添加更多类型

  const MessageData({
    required this.text,
    this.images,
    this.audio,
    this.file,
    this.cloudFileName,
    this.fileContent,
    this.videos,
  });
}

/// 输入栏组件
/// 2025-04-10 桌面端不支持语音输入和拍照
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(MessageData) onSend;
  final VoidCallback? onCancel;
  final bool isEditing;
  final bool isStreaming;
  final VoidCallback? onStop;
  final FocusNode? focusNode;
  final CusLLMSpec? model;
  // 输入框高度变化回调
  // (切换模型后，可能会展开/收起更多工具栏，导致整个输入区域变化。
  // 而主页面的悬浮开启新对话、滚动到底部按钮是相对固定在输入框上面一点
  // 输入框高度变化了，也要通知父组件，让父组件重新布局悬浮按钮)
  final ValueChanged<double>? onHeightChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onCancel,
    this.isEditing = false,
    this.isStreaming = false,
    this.onStop,
    this.focusNode,
    this.model,
    this.onHeightChanged,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _showToolbar = false;

  // 选中的图片
  List<File>? _selectedImages;
  // 选中的音频
  File? _selectedAudio;

  // 文件是否在解析中
  bool isLoadingDocument = false;
  // 被选中的文件
  File? _selectedFile;
  // 解析后的文件内容(本地和云端同时只能有一个，所以用一个变量记录)
  String _fileContent = '';
  // 云端文档的文件名(本地能获取到文件，云端只有文件名)
  String _cloudFileName = '';

  // 是否是语音输入模式
  bool _isVoiceMode = false;

  // 获取当前模型支持的工具列表
  List<ToolItem> get _toolItems {
    if (widget.model == null) return [];

    final List<ToolItem> tools = [
      // 基础工具 - 所有模型都支持
    ];

    // 根据模型类型添加特定工具
    switch (widget.model!.modelType) {
      case LLModelType.vision || LLModelType.vision_reasoner:
        tools.addAll([
          ToolItem(
            icon: Icons.image,
            label: '相册',
            type: 'upload_image',
            onTap: () => _handleImagePick(CusImageSource.gallery),
          ),
          if (!ScreenHelper.isDesktop())
            ToolItem(
              icon: Icons.camera_alt,
              label: '拍照',
              type: 'take_photo',
              onTap: () => _handleImagePick(CusImageSource.camera),
            ),
        ]);
        break;
      case LLModelType.audio:
        tools.add(
          ToolItem(
            icon: Icons.mic,
            label: '音频',
            type: 'upload_audio',
            onTap: _handleAudioUpload,
          ),
        );
        break;
      case LLModelType.cc:
        tools.addAll([
          ToolItem(
            icon: Icons.file_open,
            label: '本地文档',
            type: 'upload_file',
            onTap: _handleFileUpload,
            color: Colors.grey,
          ),
          ToolItem(
            icon: Icons.cloud_upload,
            label: '云端文档',
            type: 'upload_cloud_file',
            onTap: _handleCloudFileUpload,
            color: Colors.grey,
          ),
        ]);
        break;
      default:
        break;
    }

    return tools;
  }

  // 添加一个变量记录上次通知给父组件输入框的高度
  // (高度有变化后才重新通知，避免在didUpdateWidget中重复通知)
  double _lastNotifiedHeight = 0;

  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 初始化时获取输入框高度
    _notifyHeightChange();
  }

  Future<bool> _checkPermissions() async {
    if (!(await requestMicrophonePermission())) {
      if (!mounted) return false;
      commonExceptionDialog(context, '未授权语音录制权限', '未授权语音录制权限，无法语音输入');
      return false;
    }
    if (!(await requestStoragePermission())) {
      if (!mounted) return false;
      commonExceptionDialog(context, '未授权访问设备外部存储', '未授权访问设备外部存储，无法进行语音识别');
      return false;
    }
    return true;
  }

  // 通知父组件输入框高度变化，重新布局悬浮按钮
  void _notifyHeightChange() {
    // 等待下一帧布局完成后再获取高度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_containerKey.currentContext == null) return;

      final RenderBox renderBox =
          _containerKey.currentContext!.findRenderObject() as RenderBox;
      final height = renderBox.size.height;

      // 只在高度真正发生变化时才通知
      if (height != _lastNotifiedHeight) {
        debugPrint('ChatInput height changed: $_lastNotifiedHeight -> $height');
        _lastNotifiedHeight = height;
        widget.onHeightChanged?.call(height);
      }
    });
  }

  // 处理图片选择
  Future<void> _handleImagePick(CusImageSource source) async {
    try {
      // 相册可选多张
      if (source == CusImageSource.gallery) {
        final images = await ImagePickerUtils.pickMultipleImages();

        if (images.isNotEmpty) {
          setState(() => _selectedImages = images);
        }
      } else {
        // 拍照只有1张
        final image = await ImagePickerUtils.takePhotoAndSave();
        if (image != null) {
          setState(() => _selectedImages = [image]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '选择图片失败', '选择图片失败: $e');
    }
  }

  Future<void> _handleCloudFileUpload() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FileUploadPage(
              onFileAnalyze: (String fileContent, String fileName) {
                // 在这里处理文件内容
                setState(() {
                  _selectedFile = null;
                  _cloudFileName = fileName;
                  _fileContent = fileContent;
                  isLoadingDocument = false;
                });
              },
            ),
      ),
    );
  }

  // 处理文件上传
  Future<void> _handleFileUpload() async {
    // 只支持单个文件，如果点击上传按钮，就无论如何都清空旧的选中
    setState(() {
      isLoadingDocument = false;
      _fileContent = '';
      _selectedFile = null;
      // 处理本地文件时确保云端文档的文件名始终为空
      _cloudFileName = "";
    });

    /// 选择文件，并解析出文本内容
    File? file = await FilePickerUtils.pickAndSaveFile(
      fileType: CusFileType.custom,
      allowedExtensions:
          ScreenHelper.isDesktop()
              ? ['pdf', 'docx', 'doc']
              : ['pdf', 'txt', 'docx', 'doc'],
    );

    if (file != null) {
      setState(() {
        isLoadingDocument = true;
        _fileContent = '';
        _selectedFile = null;
        // 处理本地文件时确保云端文档的文件名始终为空
        _cloudFileName = "";
      });

      String fileExtension = file.path.split('.').last;

      try {
        var text = "";
        switch (fileExtension) {
          case 'txt':
            DecodingResult result = await CharsetDetector.autoDecode(
              File(file.path).readAsBytesSync(),
            );
            text = result.string;
          case 'pdf':
            text = await compute(extractTextFromPdf, file.path);
          case 'docx':
            text = await compute(docxToText, File(file.path).readAsBytesSync());
          case 'doc':
            text = await DocText().extractTextFromDoc(file.path) ?? "";
          default:
            debugPrint("默认的,暂时啥都不做");
        }

        if (!mounted) return;
        setState(() {
          _selectedFile = file;
          _fileContent = text;
          isLoadingDocument = false;
          // 处理本地文件时确保云端文档的文件名始终为空
          _cloudFileName = "";
        });
      } catch (e) {
        if (!mounted) return;
        commonExceptionDialog(context, '文件解析失败', '文件解析失败: $e');

        setState(() {
          _selectedFile = file;
          _fileContent = "";
          isLoadingDocument = false;
          // 处理本地文件时确保云端文档的文件名始终为空
          _cloudFileName = "";
        });
        rethrow;
      }
    }
  }

  // 处理音频上传
  Future<void> _handleAudioUpload() async {
    // TODO: 实现音频上传
  }

  // 清理选中的媒体文件
  void _clearSelectedMedia() {
    setState(() {
      _selectedImages = null;
      _selectedAudio = null;
      _selectedFile = null;

      _cloudFileName = "";
      _fileContent = '';

      // 一般取消、发送完之后都会清除媒体资源，同时也收起工具栏，并通知父组件修改悬浮按钮位置
      _showToolbar = false;
      _notifyHeightChange();
    });
  }

  // 处理发送消息
  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty &&
        _selectedImages == null &&
        _selectedAudio == null &&
        _selectedFile == null &&
        _fileContent.isEmpty &&
        _cloudFileName.isEmpty) {
      return;
    }

    // 创建消息数据
    final messageData = MessageData(
      text: text,
      images: _selectedImages,
      audio: _selectedAudio,
      file: _selectedFile,
      cloudFileName: _cloudFileName,
      fileContent: _fileContent,
    );

    // 发送消息
    widget.onSend(messageData);

    // 清理状态
    setState(() {
      _clearSelectedMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: _containerKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 选中的媒体预览
        if (_selectedImages != null) _buildImagePreviewArea(),

        if (isLoadingDocument ||
            (_selectedFile != null || _fileContent.isNotEmpty))
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: buildFilePreviewArea(),
          ),

        /// 输入栏
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              /// 工具栏切换按钮
              if (!widget.isStreaming && widget.model != null)
                IconButton(
                  icon: Icon(
                    _showToolbar ? Icons.keyboard_arrow_down : Icons.add,
                    color: _showToolbar ? Theme.of(context).primaryColor : null,
                  ),
                  onPressed: () {
                    setState(() => _showToolbar = !_showToolbar);
                    _notifyHeightChange();
                  },
                  tooltip: _showToolbar ? '收起工具栏' : '展开工具栏',
                ),

              /// 输入区域
              Expanded(child: _buildInputArea()),

              /// 发送/终止按钮
              IconButton(
                icon: Icon(
                  widget.isStreaming
                      ? Icons.stop
                      : (widget.isEditing ? Icons.check : Icons.send),
                ),
                onPressed: widget.isStreaming ? widget.onStop : _handleSend,
                tooltip:
                    widget.isStreaming
                        ? '停止生成'
                        : (widget.isEditing ? '确认编辑' : '发送'),
              ),
            ],
          ),
        ),

        /// 工具栏
        if (_showToolbar && _toolItems.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [..._toolItems.map((tool) => _buildToolButton(tool))],
            ),
          ),
      ],
    );
  }

  // 选中的图片预览区域
  Widget _buildImagePreviewArea() {
    _notifyHeightChange();

    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              children: [
                Image.file(
                  File(_selectedImages![index].path),
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: -16,
                  top: -16,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        _selectedImages!.removeAt(index);
                        if (_selectedImages!.isEmpty) {
                          _selectedImages = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 上传文件按钮和上传的文件名
  Widget buildFilePreviewArea() {
    _notifyHeightChange();

    var mainWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedFile?.path.split('/').last ?? _cloudFileName,
          maxLines: 2,
          style: TextStyle(fontSize: 12),
        ),
        RichText(
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          text: TextSpan(
            children: [
              if (_selectedFile != null)
                TextSpan(
                  text: formatFileSize(_selectedFile?.lengthSync() ?? 0),
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              TextSpan(
                text: " 文档解析完成 ",
                style: TextStyle(color: Colors.blue, fontSize: 15),
              ),
              TextSpan(
                text: "共有 ${_fileContent.length} 字符",
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(width: 10),
        Expanded(
          child:
              (_selectedFile != null || _fileContent.isNotEmpty)
                  ? GestureDetector(
                    onTap: () {
                      previewDocumentContent();
                    },
                    child: mainWidget,
                  )
                  : Center(
                    child: Text(
                      isLoadingDocument ? "文档解析中,请勿操作..." : "可点击左侧按钮上传文件",
                      // style: const TextStyle(color: Colors.grey),
                    ),
                  ),
        ),
        if (_selectedFile != null || _cloudFileName.isNotEmpty)
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _fileContent = "";
                  _cloudFileName = "";
                  _selectedFile = null;
                  _notifyHeightChange();
                });
              },
              icon: const Icon(Icons.clear),
            ),
          ),
      ],
    );
  }

  /// 点击上传文档名称，可预览文档内容
  void previewDocumentContent() {
    var mainWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('解析后文档内容预览', style: TextStyle(fontSize: 18)),
              TextButton(
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.pop(context);
                  unfocusHandle();
                },
              ),
            ],
          ),
        ),
        Divider(height: 2, thickness: 2),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(10),
              // 2025-03-22 这里解析出来的内容可能包含非法字符，所以就算使用Text或者Text.rich，都会报错
              // 使用MarkdownBody也会报错，但能显示出来，上面是无法显示
              child:
                  _fileContent.length > 8000
                      ? Text(
                        "解析后内容过长${_fileContent.length}字符，只展示前8000字符\n\n${_fileContent.substring(0, 8000)}\n <已截断...>",
                      )
                      : MarkdownBody(
                        data: String.fromCharCodes(_fileContent.runes),
                        // selectable: true,
                      ),
            ),
          ),
        ),
      ],
    );

    ScreenHelper.isDesktop()
        ? showDialog(
          context: context,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            return AlertDialog(
              content: SizedBox(width: screenWidth * 0.6, child: mainWidget),
            );
          },
        )
        : showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return SizedBox(height: 0.8.sh, child: mainWidget);
          },
        );
  }

  // 切换语音输入或文本输入按钮（桌面端显示键盘图标，不支持切换）
  Widget _buildVoiceModeButton() {
    return ScreenHelper.isMobile()
        ? IconButton(
          icon: Icon(
            _isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
            size: 20,
          ),
          onPressed:
              widget.isStreaming
                  ? null
                  : () async {
                    if (!_isVoiceMode && !await _checkPermissions()) {
                      return;
                    }
                    setState(() => _isVoiceMode = !_isVoiceMode);
                  },
        )
        : Icon(Icons.keyboard, size: 20);
  }

  // 输入区域
  Widget _buildInputArea() {
    if (_isVoiceMode) {
      var smButton = SoundsMessageButton(
        // 不要边框和阴影等，方便设置背景图片好看
        customDecoration: BoxDecoration(color: Colors.transparent),
        onChanged: (status) {},
        onSendSounds:
            widget.isStreaming
                ? (type, content) {
                  commonExceptionDialog(context, '提示', '等待响应完成或终止后再输入');
                }
                : (type, content) async {
                  if (content.isEmpty) {
                    commonExceptionDialog(context, '提示', '请输入消息内容');
                    return;
                  }

                  if (type == SendContentType.text) {
                    // 如果输入的是语音转换后的文字，直接发送文字
                    final messageData = MessageData(
                      text: content,
                      images: _selectedImages,
                      audio: _selectedAudio,
                      file: _selectedFile,
                      fileContent: _fileContent,
                    );

                    widget.onSend(messageData);
                  } else if (type == SendContentType.voice) {
                    // 如果直接输入的语音，要显示转换后的文本，也要保留语音文件
                    String tempPath = path.join(
                      path.dirname(content),
                      path.basenameWithoutExtension(content),
                    );

                    var transcription = await getTextFromAudioFromXFYun(
                      "$tempPath.pcm",
                    );

                    final messageData = MessageData(
                      text: transcription,
                      images: _selectedImages,
                      audio: File("$tempPath.m4a"),
                      file: _selectedFile,
                      fileContent: _fileContent,
                    );

                    widget.onSend(messageData);
                  }

                  // 清理状态
                  setState(() {
                    _clearSelectedMedia();
                  });
                },
      );

      return Container(
        height: 58,
        decoration: BoxDecoration(
          // color: Colors.white,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Row(
          children: [
            _buildVoiceModeButton(),
            Expanded(child: smButton),
            // 占位宽度，眼睛看的，大概让"按住说话"几个字居中显示
            SizedBox(width: 40),
          ],
        ),
      );
    } else {
      return Focus(
        onKeyEvent: (node, event) {
          // 仅在桌面平台上处理特殊的键盘事件
          if (ScreenHelper.isDesktop() &&
              event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            // 检查是否按下了Shift键
            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

            // 如果按下Shift键则执行换行（让事件继续传递）
            // 如果未按下Shift键则发送消息
            if (!isShiftPressed) {
              _handleSend();
              return KeyEventResult.handled; // 阻止默认换行
            }
          }
          return KeyEventResult.ignored; // 其他情况或移动平台上忽略
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: !widget.isStreaming,
          maxLines: 3,
          minLines: 1,
          onChanged: (value) {
            _notifyHeightChange();
          },
          decoration: InputDecoration(
            hintText: widget.isEditing ? '编辑消息...' : '输入消息...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon:
                (widget.isEditing && widget.onCancel != null)
                    ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _clearSelectedMedia();
                        });
                        widget.onCancel?.call();
                      },
                      tooltip: '取消编辑',
                    )
                    : _buildVoiceModeButton(),
          ),
        ),
      );
    }
  }

  // 工具项按钮
  Widget _buildToolButton(ToolItem tool) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tool.icon, size: 24, color: tool.color),
              SizedBox(height: 4),
              Text(
                tool.label,
                style: TextStyle(fontSize: 12, color: tool.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 工具项数据类
class ToolItem {
  final IconData icon;
  final String label;
  final String type;
  final VoidCallback onTap;
  final Color? color;
  const ToolItem({
    required this.icon,
    required this.label,
    required this.type,
    required this.onTap,
    this.color,
  });
}
