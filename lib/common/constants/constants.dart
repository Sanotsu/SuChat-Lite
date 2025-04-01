// 时间格式化字符串
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:io';

const constDatetimeFormat = "yyyy-MM-dd HH:mm:ss";
const constDateFormat = "yyyy-MM-dd";
const constMonthFormat = "yyyy-MM";
const constTimeFormat = "HH:mm:ss";
// 文件名后缀等
const constDatetimeSuffix = "yyyyMMdd_HHmmss";
// 未知的时间字符串
const unknownDateTimeString = '1970-01-01 00:00:00';
const unknownDateString = '1970-01-01';

const String placeholderImageUrl = 'assets/images/no_image.png';
const String brandImageUrl = 'assets/brand.png';
const String defaultAvatarUrl = 'assets/characters/default_avatar.png';

// 数据库分页查询数据的时候，还需要带上一个该表的总数量
// 还可以按需补入其他属性
class CusDataResult {
  List<dynamic> data;
  int total;

  CusDataResult({required this.data, required this.total});
}

// 自定义标签，常用来存英文、中文、全小写带下划线的英文等。
class CusLabel {
  final String? enLabel;
  final String cnLabel;
  final dynamic value;

  CusLabel({this.enLabel, required this.cnLabel, required this.value});

  @override
  String toString() {
    return '''
    CusLabel{
      enLabel: $enLabel, cnLabel: $cnLabel, value:$value
    }
    ''';
  }
}

/// 保存文档解读、图片解读结果的目录
final FILE_INTERPRET_DIR = Directory(
  '/storage/emulated/0/SWMate/file_interpret',
);

/// 智能对话和多聊中对话语音文件目录
final CHAT_AUDIO_DIR = Directory('/storage/emulated/0/SWMate/chat_audio');

/// 所有的文生图、图生图都保存在同一个位置
final LLM_IG_DIR = Directory('/storage/emulated/0/SWMate/image_generation');

///  新版本的文生图(2025-02-18保存在系统的pictures目录下photo_manager扫不到)
final LLM_IG_DIR_V2 = Directory(
  '/storage/emulated/0/SWMate/brief_image_generation',
);

/// 所有的文生视频都保存在同一个位置
final LLM_VG_DIR = Directory('/storage/emulated/0/SWMate/video_generation');

/// 所有的视频都保存在同一个位置
final LLM_VG_DIR_V2 = Directory(
  '/storage/emulated/0/SWMate/brief_video_generation',
);

/// 一般性质的文件下载的位置
final DL_DIR = Directory('/storage/emulated/0/SWMate/download');

// 大模型对话的角色枚举
enum CusRole { system, user, assistant }

// 2025-02-25 新版本图片、视频等AI生成资源管理页面，使用mime获取分类时自定义的key枚举
// 自定义媒体资源分类 custom mime classification
enum CusMimeCls { IMAGE, VIDEO, AUDIO }
