import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
import '../../domain/entities/input_message_data.dart';
import '../pages/file_upload_to_bigmodel_page.dart';

/// 输入栏组件
/// 2025-04-10 桌面端不支持语音输入和拍照
class BranchChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(InputMessageData) onSend;
  final VoidCallback? onCancel;
  final bool isEditing;
  final bool isStreaming;
  final VoidCallback? onStop;
  final FocusNode? focusNode;
  final CusLLMSpec? model;
  // 输入框高度变化回调
  final ValueChanged<double>? onHeightChanged;

  const BranchChatInputBar({
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
  State<BranchChatInputBar> createState() => _BranchChatInputBarState();
}

class _BranchChatInputBarState extends State<BranchChatInputBar> {
  // 选中的图片
  List<File>? _selectedImages;
  // 选中的音频(2025-05-30 用户选择音频暂时只支持单个，但传递时还是去构建一个数组)
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

  // 添加一个变量记录上次通知给父组件输入框的高度
  double _lastNotifiedHeight = 0;

  // 如果是阿里云多模态，可以指定声音音色(如果不是无，则生成音频;如果是无，则不生成音频)
  String _selectedOmniAudioVoice = '无音频';

  // 千问omni音色选项
  final List<String> _omniAudioVoiceList = [
    '无音频',
    'Cherry',
    'Serena',
    'Ethan',
    'Chelsie',
  ];

  // 2025-09-10 是否联网搜索(阿里云的部分模型支持)
  bool _enableWebSearch = false;

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
        builder: (context) => FileUploadPage(
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
    /// 2025-06-17 由于之前手动解析docx、doc文件的依赖太老，和限制了一些常用依赖使用新版本，
    /// 前目前没有实际完成上传，所以暂时只支持pdf，移除了doc_text、docx_to_text依赖
    File? file = await FilePickerUtils.pickAndSaveFile(
      fileType: CusFileType.custom,
      allowedExtensions: ScreenHelper.isDesktop() ? ['pdf'] : ['pdf', 'txt'],
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

  // 处理音频上传(预留，暂时没处理音频理解大模型)
  Future<void> _handleAudioUpload() async {
    try {
      // 现在没有实际的音频大模型，所以只能选择一个音频文件
      File? file = await FilePickerUtils.pickAndSaveFile(
        fileType: CusFileType.audio,
      );

      if (file != null) {
        if (!mounted) return;
        setState(() {
          _selectedAudio = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '选择音频失败', '选择音频失败: $e');
    }
  }

  // 清理选中的媒体文件
  void _clearSelectedMedia() {
    setState(() {
      _selectedImages = null;
      _selectedAudio = null;
      _selectedFile = null;

      _cloudFileName = "";
      _fileContent = '';

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
    final messageData = InputMessageData(
      text: text,
      images: _selectedImages,
      audios: _selectedAudio != null ? [_selectedAudio!] : null,
      file: _selectedFile,
      cloudFileName: _cloudFileName,
      fileContent: _fileContent,
      omniAudioVoice: _selectedOmniAudioVoice,
      enableWebSearch: _enableWebSearch,
    );

    // 发送消息
    widget.onSend(messageData);

    // 清理状态
    setState(() {
      widget.controller.clear();
      _clearSelectedMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 预览区域 (如果有选中的图片或文件)
          if (_selectedImages != null ||
              isLoadingDocument ||
              _selectedFile != null ||
              _fileContent.isNotEmpty ||
              _selectedAudio != null)
            _buildPreviewArea(),

          // 输入区域
          _buildInputArea(),

          // 工具栏区域
          _buildToolbar(),
        ],
      ),
    );
  }

  // 预览区域
  Widget _buildPreviewArea() {
    _notifyHeightChange();

    if (_selectedImages != null) {
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImages![index].path),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -12,
                    top: -12,
                    child: IconButton(
                      icon: Icon(
                        Icons.cancel,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
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
    } else if (isLoadingDocument ||
        _selectedFile != null ||
        _fileContent.isNotEmpty) {
      return Container(
        height: 100,
        padding: EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedFile?.path.split('/').last ?? _cloudFileName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (isLoadingDocument)
                    Text("文档解析中...", style: TextStyle(color: Colors.grey))
                  else
                    GestureDetector(
                      onTap: () => previewDocumentContent(),
                      child: Text(
                        "文档解析完成，共${_fileContent.length}字符 (点击预览)",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _fileContent = "";
                  _cloudFileName = "";
                  _selectedFile = null;
                  _notifyHeightChange();
                });
              },
            ),
          ],
        ),
      );
    } else if (_selectedAudio != null) {
      return Container(
        height: 60,
        padding: EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.audiotrack, color: Colors.blue, size: 40),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedAudio!.path.split('/').last,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedAudio = null;
                  _notifyHeightChange();
                });
              },
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  // 输入区域
  Widget _buildInputArea() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: _isVoiceMode ? _buildVoiceInputArea() : _buildTextInputArea(),
    );
  }

  // 语音输入区域
  Widget _buildVoiceInputArea() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: SoundsMessageButton(
        // 不要边框和阴影等，方便设置背景图片好看
        customDecoration: BoxDecoration(color: Colors.transparent),
        onChanged: (status) {},
        onSendSounds: widget.isStreaming
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
                  final messageData = InputMessageData(
                    text: content,
                    images: _selectedImages,
                    audios: _selectedAudio != null ? [_selectedAudio!] : null,
                    file: _selectedFile,
                    cloudFileName: _cloudFileName,
                    fileContent: _fileContent,
                    omniAudioVoice: _selectedOmniAudioVoice,
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

                  final messageData = InputMessageData(
                    text: transcription,
                    images: _selectedImages,
                    sttAudio: File("$tempPath.m4a"),
                    audios: _selectedAudio != null ? [_selectedAudio!] : null,
                    file: _selectedFile,
                    cloudFileName: _cloudFileName,
                    fileContent: _fileContent,
                    omniAudioVoice: _selectedOmniAudioVoice,
                  );

                  widget.onSend(messageData);
                }

                // 清理状态
                setState(() {
                  _clearSelectedMedia();
                });
              },
      ),
    );
  }

  // 文本输入区域
  Widget _buildTextInputArea() {
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
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          prefixIcon: widget.isEditing && widget.onCancel != null
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
              : null,
        ),
      ),
    );
  }

  // 工具栏区域
  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // 语音/键盘切换按钮
          if (ScreenHelper.isMobile())
            IconButton(
              icon: Icon(
                _isVoiceMode ? Icons.keyboard : Icons.keyboard_voice,
                size: 20,
              ),
              onPressed: widget.isStreaming
                  ? null
                  : () async {
                      if (!_isVoiceMode && !await _checkPermissions()) {
                        return;
                      }
                      setState(() => _isVoiceMode = !_isVoiceMode);
                    },
              tooltip: _isVoiceMode ? '切换到键盘' : '切换到语音',
            ),

          // 图片按钮
          if (widget.model?.modelType == LLModelType.vision ||
              widget.model?.modelType == LLModelType.vision_reasoner ||
              widget.model?.modelType == LLModelType.omni)
            IconButton(
              icon: Icon(Icons.image, size: 20),
              onPressed: widget.isStreaming
                  ? null
                  : () => _handleImagePick(CusImageSource.gallery),
              tooltip: '从相册选择图片',
            ),

          // 2025-09-10 是否联网搜索按钮
          // 注意，只有阿里云平台的少量模型支持
          if (widget.model != null &&
              (zhipuWebSearchModels + aliyunWebSearchModels).contains(
                widget.model!.model,
              ))
            IconButton(
              icon: Icon(
                _enableWebSearch ? Icons.wifi : Icons.wifi_off,
                size: 20,
              ),
              onPressed: widget.isStreaming
                  ? null
                  : () {
                      setState(() {
                        _enableWebSearch = !_enableWebSearch;
                      });
                    },
              tooltip: _enableWebSearch ? '启用联网搜索' : '禁用联网搜索',
            ),

          // 拍照按钮 (移动端)
          if ((widget.model?.modelType == LLModelType.vision ||
                  widget.model?.modelType == LLModelType.vision_reasoner) &&
              !ScreenHelper.isDesktop())
            IconButton(
              icon: Icon(Icons.camera_alt, size: 20),
              onPressed: widget.isStreaming
                  ? null
                  : () => _handleImagePick(CusImageSource.camera),
              tooltip: '拍照',
            ),

          // 文档按钮
          if (widget.model?.modelType == LLModelType.cc ||
              widget.model?.modelType == LLModelType.reasoner)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.file_open, color: Colors.grey, size: 20),
                  onPressed: widget.isStreaming ? null : _handleFileUpload,
                  tooltip: '上传本地文档',
                ),
                IconButton(
                  icon: Icon(Icons.cloud_upload, color: Colors.grey, size: 20),
                  onPressed: widget.isStreaming ? null : _handleCloudFileUpload,
                  tooltip: '上传云端文档',
                ),
              ],
            ),

          // 音频按钮
          if (widget.model?.modelType == LLModelType.audio ||
              widget.model?.modelType == LLModelType.omni)
            IconButton(
              icon: Icon(Icons.audio_file, size: 20),
              onPressed: widget.isStreaming ? null : _handleAudioUpload,
              tooltip: '上传音频',
            ),

          if (widget.model?.modelType == LLModelType.omni &&
              (widget.model != null && widget.model!.model.contains("omni")))
            _buildOmniAudioVoiceDropdown(),

          Spacer(),

          // 发送/停止按钮
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.isStreaming ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                widget.isStreaming
                    ? Icons.stop
                    : (widget.isEditing
                          ? Icons.check
                          : Icons.arrow_upward_outlined),
                color: Colors.white,
                size: 24,
              ),
              onPressed: widget.isStreaming ? widget.onStop : _handleSend,
              tooltip: widget.isStreaming
                  ? '停止生成'
                  : (widget.isEditing ? '确认编辑' : '发送'),
              padding: EdgeInsets.zero, // 移除默认的内边距
            ),
          ),
        ],
      ),
    );
  }

  // 构建图像尺寸选择下拉框
  Widget _buildOmniAudioVoiceDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: DropdownButton<String>(
        value: _selectedOmniAudioVoice,
        icon: Icon(
          Icons.audiotrack,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        isDense: true,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedOmniAudioVoice = newValue;
            });
          }
        },
        items: _omniAudioVoiceList.map<DropdownMenuItem<String>>((
          String value,
        ) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
      ),
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
              child: _fileContent.length > 8000
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
}
