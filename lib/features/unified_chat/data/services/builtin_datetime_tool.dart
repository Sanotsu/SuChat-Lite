import '../models/openai_request.dart';

/// 2026-09-14 内置时间工具(客户端本地时钟，无需联网)：
/// 大模型不知道"今天/明天/昨天"等相对表述对应的实际日期(训练截止+
/// 推理时无时钟)，联网搜索也未必可靠——通过工具调用把设备当前时间
/// 注入对话，模型据此精确换算相对日期。
/// 调研结论(2026-09-14)：时间类MCP server几乎全是stdio本地运行形态
/// (官方mcp-server-time等)，无免费公共远程端点，且设备时钟本身即
/// 最准时间源——故做成内置工具而非MCP接入。
class BuiltinDateTimeTool {
  BuiltinDateTimeTool._();

  static const String toolName = 'get_current_time';

  /// OpenAI function工具定义(注入request.tools)
  static OpenAITool buildTool() {
    return OpenAITool.function(
      const OpenAIFunction(
        name: toolName,
        description:
            '获取设备当前的日期与时间。当用户提到"今天/今日/昨天/前天/明天/后天/现在/'
            '最近/本周/下周/本月/上个月"等相对时间表述，或回答需要知道当前日期时，'
            '必须先调用本工具获取准确时间基准，不要凭训练记忆猜测日期。',
        parameters: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{},
          'required': <String>[],
        },
      ),
    );
  }

  /// 执行工具(纯读本地时钟，不会失败)，返回注入对话的时间信息文本。
  /// 附常用相对日期对照表，模型拿到即可精确回答"今天/明天/昨天"等
  static String execute() {
    final now = DateTime.now();
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    String weekday(DateTime d) => weekdays[d.weekday - 1];
    String two(int v) => v.toString().padLeft(2, '0');
    String fmtDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
    String fmt(DateTime d) =>
        '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

    final totalOffsetMinutes = now.timeZoneOffset.inMinutes;
    final sign = totalOffsetMinutes < 0 ? '-' : '+';
    final absMinutes = totalOffsetMinutes.abs();
    final offsetStr =
        'UTC$sign${(absMinutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(absMinutes % 60).toString().padLeft(2, '0')}';

    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final thisSunday = thisMonday.add(const Duration(days: 6));
    final nextMonday = thisMonday.add(const Duration(days: 7));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month);
    String rel(DateTime d) => '${fmtDate(d)} (${weekday(d)})';

    final buffer = StringBuffer()
      ..writeln('当前时间信息(设备本地时钟)：')
      ..writeln('- 本地日期时间: ${fmt(now)} (${weekday(now)})')
      ..writeln('- 时区: ${now.timeZoneName} ($offsetStr)')
      ..writeln('- ISO8601: ${now.toIso8601String()}')
      ..writeln('- UTC日期时间: ${fmt(now.toUtc())}')
      ..writeln('- Unix时间戳(毫秒): ${now.millisecondsSinceEpoch}')
      ..writeln('相对日期对照(可直接用于回答)：')
      ..writeln('- 前天: ${rel(now.subtract(const Duration(days: 2)))}')
      ..writeln('- 昨天: ${rel(now.subtract(const Duration(days: 1)))}')
      ..writeln('- 今天: ${rel(now)}')
      ..writeln('- 明天: ${rel(now.add(const Duration(days: 1)))}')
      ..writeln('- 后天: ${rel(now.add(const Duration(days: 2)))}')
      ..writeln('- 本周一: ${fmtDate(thisMonday)}，本周日: ${fmtDate(thisSunday)}')
      ..writeln('- 下周一: ${fmtDate(nextMonday)}，下周日: ${fmtDate(nextSunday)}')
      ..writeln('- 本月1号: ${fmtDate(monthStart)}');
    return buffer.toString();
  }
}
