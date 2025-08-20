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

  // 2025-08-12 不重写这两个方法，Dart 会默认使用 对象的内存地址（引用） 进行比较，而不是内容。
  // 重写之后，就算内存地址不一样的两个实例，因为数据一样，就当成同一个实例了
  // 比如 BaseNewsPageState 中：
  // buildDropdownButton2() 会基于 value 判断两个 CusLabel 是否相等，而不是内存地址。
  // 即使 getCategories() 每次返回新对象，只要 value buildDropdownButton2() 就能正确匹配。
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CusLabel &&
        enLabel == other.enLabel &&
        cnLabel == other.cnLabel &&
        value == other.value;
  }

  @override
  int get hashCode => enLabel.hashCode ^ cnLabel.hashCode ^ value.hashCode;

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
