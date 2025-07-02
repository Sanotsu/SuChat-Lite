// 时间格式化字符串
const formatToYMDHMS = "yyyy-MM-dd HH:mm:ss";
const formatToYMDHM = "yyyy-MM-dd HH:mm";
const formatToYMDH = "yyyy-MM-dd HH";
const formatToYMD = "yyyy-MM-dd";
const formatToYM = "yyyy-MM";
const formatToMD = "MM-dd";
const formatToY = "yyyy";
const formatToMDHM = "MM-dd HH:mm";
const formatToHMS = "HH:mm:ss";
const formatToHM = "HH:mm";

// 中文的带中文后缀
const formatToYMDHMSzh = "yyyy年MM月dd日 HH:mm:ss";
const formatToYMDHMzh = "yyyy年MM月dd日 HH:mm";
const formatToYMDHSzh = "yyyy年MM月dd日 HH";
const formatToYMDzh = "yyyy年MM月dd日";
const formatToYMzh = "yyyy年MM月";
const formatToMDzh = "MM月dd日";
const formatToYzh = "yyyy年";
const formatToMDHMzh = "MM月dd日 HH:mm";
const formatToHMSzh = "HH:mm:ss";
const formatToHMzh = "HH:mm";

// 文件名后缀等
const constDatetimeSuffix = "yyyyMMdd_HHmmss";
// 未知的时间字符串
const unknownDateTimeString = '1970-01-01 00:00:00';
const unknownDateString = '1970-01-01';

/// 默认的日历显示范围
final kToday = DateTime.now();
final kFirstDay = DateTime(2025, 6, 1);
final kLastDay = DateTime(kToday.year, kToday.month + 3, 25);

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

// 大模型对话的角色枚举
enum CusRole { system, user, assistant }

// 2025-02-25 新版本图片、视频等AI生成资源管理页面，使用mime获取分类时自定义的key枚举
// 自定义媒体资源分类 custom mime classification
// ignore: constant_identifier_names
enum CusMimeCls { IMAGE, VIDEO, AUDIO }

/// 映射表：将数字映射到中文星期几（1-7表示周一到周日）
final Map<int, String> dayWeekMapping = {
  1: '周一',
  2: '周二',
  3: '周三',
  4: '周四',
  5: '周五',
  6: '周六',
  7: '周日',
};

/// 映射表：将中文星期几映射到数字（1-7表示周一到周日）
final Map<String, int> weekDayMapping = {
  '周一': 1,
  '周二': 2,
  '周三': 3,
  '周四': 4,
  '周五': 5,
  '周六': 6,
  '周日': 7,
};
