import 'package:intl/intl.dart';

import '../../shared/constants/constants.dart';

///
/// 和时间相关的方法(不管是格式化成字符串，还是转为时间类型)
///

/// 餐次时间
String getTimePeriod() {
  DateTime now = DateTime.now();
  if (now.hour >= 0 && now.hour < 9) {
    return '早餐';
  } else if (now.hour >= 9 && now.hour < 11) {
    return '早茶';
  } else if (now.hour >= 11 && now.hour < 14) {
    return '午餐';
  } else if (now.hour >= 14 && now.hour < 16) {
    return '下午茶';
  } else if (now.hour >= 16 && now.hour < 20) {
    return '晚餐';
  } else {
    return '夜宵';
  }
}

/// 格式化Duration为 HH:MM:SS格式
String formatDurationToString(Duration d) =>
    d.toString().split('.').first.padLeft(8, "0");

/// 格式化时间戳为带微秒的时间戳
/// fileTs => fileNameTimestamp
String fileTs(DateTime dateTime) {
  final formatted = DateFormat(constDatetimeSuffix).format(dateTime);
  final us = (dateTime.microsecondsSinceEpoch % 1000000).toString().padLeft(
    6,
    '0',
  );
  return '${formatted}_$us';
}

/// 格式化时间label中文
String formatTimeAgo(String timeString) {
  if (timeString.isEmpty) return "未知";

  DateTime dateTime = DateTime.parse(timeString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years年前';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months月前';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}天前';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}小时前';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}分钟前';
  } else {
    return '${difference.inSeconds}秒前';
  }
}

// 英文显示有单数复数之分
String formatTimeAgoEn(String timeString) {
  DateTime dateTime = DateTime.parse(timeString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else {
    return '${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''} ago';
  }
}

// 字符串只保留月日时分
String formatTimeLabel(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(time.year, time.month, time.day);

  if (messageDate == today) {
    return DateFormat(formatToHM).format(time);
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    return '昨天 ${DateFormat(formatToHM).format(time)}';
  } else {
    return DateFormat(formatToMDHM).format(time);
  }
}

// 把各种时间字符串格式化指定格式的字符串
String formatDateTimeString(String timeString, {String? formatType}) {
  if (timeString.isEmpty) return "未知";

  return DateFormat(
    formatType ?? formatToYMDHMS,
  ).format(DateTime.tryParse(timeString) ?? DateTime.now());
}

// 10位的时间戳转字符串
String formatTimestampToString(String? timestamp, {String? format}) {
  if (timestamp == null || timestamp.isEmpty) {
    return "";
  }

  if (timestamp.trim().length == 10) {
    timestamp = "${timestamp}000";
  }

  if (timestamp.trim().length != 13) {
    return "输入的时间戳不是10位或者13位的整数";
  }

  return DateFormat(format ?? formatToYMDHMS).format(
    DateTime.fromMillisecondsSinceEpoch(
      // 如果传入的时间戳字符串转型不对，就使用 1970-01-01 23:59:59 的毫秒数
      int.tryParse(timestamp) ?? 57599000,
    ),
  );
}

// 格式化秒数为mm:ss格式
String formatSecondsToMMSS(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

/// 格式化年份和周数
String formatToYearWeek(DateTime date) {
  final year = date.year;
  final weekNumber = _getISOWeekNumber(date);
  return '$year年第$weekNumber周';
}

// 计算 ISO 周数（周一为第一天，1月4日所在的周为第一周）
int _getISOWeekNumber(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();

  if (weekNumber < 1) {
    // 处理跨年周（如12月最后几天可能属于下一年的第一周）
    return _getISOWeekNumber(DateTime(date.year - 1, 12, 31));
  } else if (weekNumber > 52 && DateTime(date.year, 12, 31).weekday < 4) {
    return 1;
  }
  return weekNumber;
}
