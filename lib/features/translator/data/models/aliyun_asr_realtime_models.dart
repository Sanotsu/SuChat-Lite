import 'dart:math';

// 实时语音识别相关模型

///
/// 2025-08-23 目前适用模型 paraformer-realtime：
/// https://help.aliyun.com/zh/model-studio/websocket-for-paraformer-real-time-service
///
///  Gummy 稍微有点不一样，没有兼容它
///
/// 实时语音识别请求参数
/// 对应文档中 payload.parameters 对象
///  类名缩写原则: 最后一个单词全程，其他少量首字母缩写或简写
///  AliyunAsrRealtimePayloadParameters => AsrRtParameter
class AsrRtParameter {
  final int sampleRate;
  final String format;
  final bool? disfluencyRemovalEnabled;
  final List<String>? languageHints;

  AsrRtParameter({
    this.sampleRate = 16000,
    this.format = 'pcm',
    this.disfluencyRemovalEnabled,
    this.languageHints,
  });

  Map<String, dynamic> toJson() {
    final params = {'sample_rate': sampleRate, 'format': format};

    if (disfluencyRemovalEnabled != null) {
      params['disfluency_removal_enabled'] = disfluencyRemovalEnabled!;
    }

    if (languageHints != null && languageHints!.isNotEmpty) {
      params['language_hints'] = languageHints!;
    }

    return params;
  }
}

/// 实时语音识别响应结果
/// 对应 result-generated 事件响应的内容
/// 大概有文档中 header 部分属性、 payload.output 和 payload.usage 对象
/// AliyunAsrRealtimePayloadOutput => AsrRtResult
class AsrRtResult {
  // header 中部分栏位
  final String? taskId;
  final String event;
  final String? errorCode;
  final String? errorMessage;

  // payload.output 中部分栏位
  final int? sentenceBeginTime;
  final int? sentenceEndTime;
  final String? text;
  final bool? heartbeat;
  final bool? sentenceEnd;
  final bool isSuccess;

  final Map<String, dynamic>? usage;

  AsrRtResult({
    this.taskId,
    required this.event,
    this.errorCode,
    this.errorMessage,
    this.sentenceBeginTime,
    this.sentenceEndTime,
    this.text,
    this.heartbeat,
    this.sentenceEnd,
    this.isSuccess = true,
    this.usage,
  });

  factory AsrRtResult.fromJson(Map<String, dynamic> json) {
    final header = json['header'] ?? {};
    final payload = json['payload'] ?? {};
    final event = header['event'] ?? '';

    String? text;
    bool? sentenceEnd;
    bool? heartbeat;
    int? sentenceBeginTime;
    int? sentenceEndTime;

    if (event == 'result-generated' && payload['output'] != null) {
      final sentence = payload['output']['sentence'];
      if (sentence != null) {
        sentenceBeginTime = sentence['begin_time'];
        sentenceEndTime = sentence['end_time'];
        text = sentence['text'];
        sentenceEnd = sentence['sentence_end'];
        heartbeat = sentence['heartbeat'];
      }
    }

    return AsrRtResult(
      // header 中部分栏位
      taskId: header['task_id'],
      event: event,
      errorCode: header['error_code'],
      errorMessage: header['error_message'],
      // payload.output 中部分栏位
      sentenceBeginTime: sentenceBeginTime,
      sentenceEndTime: sentenceEndTime,
      text: text,
      heartbeat: heartbeat,
      sentenceEnd: sentenceEnd,
      isSuccess: event != 'task-failed',
      usage: payload['usage'],
    );
  }

  bool get isTaskStarted => event == 'task-started';
  bool get isResultGenerated => event == 'result-generated';
  bool get isTaskFinished => event == 'task-finished';
  bool get isTaskFailed => event == 'task-failed';
  bool get hasError => !isSuccess;
  // 句子的中间结果时，句子的end_time 为null
  bool get shouldSkip => sentenceEndTime == null || heartbeat == true;
}

/// WebSocket消息类型
/// 2种类型：run-task 和 finish-task
/// 4种事件：task-started、result-generated、task-finished、task-failed
/// AliyunAsrRealtimeMessageAction => AsrRtMsgAction
enum AsrRtMsgAction { runTask, finishTask }

/// WebSocket消息
/// ws 发送的整个消息，包含header和payload
/// AliyunAsrRealtimeMessage => AsrRtMessage
class AsrRtMessage {
  final AsrRtMsgAction action;
  final String taskId;
  final Map<String, dynamic>? payload;

  AsrRtMessage({required this.action, required this.taskId, this.payload});

  Map<String, dynamic> toJson() {
    String actionValue;
    switch (action) {
      case AsrRtMsgAction.runTask:
        actionValue = 'run-task';
        break;
      case AsrRtMsgAction.finishTask:
        actionValue = 'finish-task';
        break;
    }

    return {
      'header': {
        'action': actionValue,
        'task_id': taskId,
        'streaming': 'duplex', // 固定字符串
      },
      'payload': payload ?? {'input': {}},
    };
  }

  /// 创建运行任务消息
  static AsrRtMessage runTask({
    required String taskId,
    required String model,
    required AsrRtParameter params,
  }) {
    return AsrRtMessage(
      action: AsrRtMsgAction.runTask,
      taskId: taskId,
      payload: {
        'task_group': 'audio', // 固定字符串
        'task': 'asr', // 固定字符串
        'function': 'recognition', // 固定字符串
        'model': model,
        'parameters': params.toJson(),
        'input': {}, // 固定格式
      },
    );
  }

  /// 创建完成任务消息
  static AsrRtMessage finishTask(String taskId) {
    return AsrRtMessage(action: AsrRtMsgAction.finishTask, taskId: taskId);
  }
}

/// 任务ID生成器
class TaskIdGenerator {
  static String generate() {
    // 生成32位随机UUID（不带横线）
    final random = Random();
    final chars = '0123456789abcdef';
    String uuid = '';

    for (int i = 0; i < 32; i++) {
      uuid += chars[random.nextInt(chars.length)];
    }

    return uuid;
  }
}
