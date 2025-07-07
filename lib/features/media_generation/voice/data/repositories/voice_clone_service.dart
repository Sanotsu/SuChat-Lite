import 'dart:io';

import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../../core/storage/cus_get_storage.dart';
import '../../../../../shared/services/github_storage_service.dart';

class ClonedVoice {
  final String? voiceId;
  final String? targetModel;
  final String? resourceLink;
  final DateTime? gmtCreate;
  final DateTime? gmtModified;
  final String? status;

  // 查询所有音色的结果，output.voice_list中的属性: voice_id \gmt_create\gmt_modified\status
  // 查询指定音色的结果，output: resource_link\target_model \gmt_create\gmt_modified\status
  ClonedVoice({
    this.voiceId,
    this.resourceLink,
    this.targetModel,
    this.gmtCreate,
    this.gmtModified,
    this.status,
  });

  factory ClonedVoice.fromJson(Map<String, dynamic> json) {
    return ClonedVoice(
      voiceId: json['voice_id'] ?? '',
      resourceLink: json['resource_link'] ?? '',
      targetModel: json['target_model'] ?? '',
      gmtCreate:
          json['gmt_create'] != null
              ? DateTime.parse(json['gmt_create'])
              : null,
      gmtModified:
          json['gmt_modified'] != null
              ? DateTime.parse(json['gmt_modified'])
              : null,
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_id': voiceId,
      'resource_link': resourceLink,
      'target_model': targetModel,
      'gmt_create': gmtCreate?.toIso8601String(),
      'gmt_modified': gmtModified?.toIso8601String(),
      'status': status,
    };
  }
}

///
/// 目前只是阿里云的声音复刻，其他平台和参数等不一定通用，所以暂时不抽出来
///
class VoiceCloneService {
  // 阿里云声音复刻API地址
  // 创建音色
  static const String _cosyvoiceCloneBaseUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/audio/tts/customization';

  /// 获取API Key
  static Future<String> _getApiKey() async {
    // 使用用户的 API Key
    final userKeys = CusGetStorage().getUserAKMap();
    String? apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未配置阿里云平台的 API Key');
    }
    return apiKey;
  }

  /// 创建HTTP请求的请求头
  static Future<Map<String, dynamic>> _getHeaders() async {
    final apiKey = await _getApiKey();
    return {
      "Authorization": "bearer $apiKey",
      "Content-Type": "application/json",
    };
  }

  /// 克隆声音
  /// [model] - 使用的模型
  /// [audioPath] - 音频文件路径
  /// [cloudAudioUrl] - 云端音频URL，如果提供则优先使用
  /// [prefix] - 音色自定义前缀，仅允许数字和小写字母，小于十个字符
  /// [targetModel] - 声音复刻所使用的模型，支持cosyvoice-v1和cosyvoice-v2
  /// 返回克隆后的音色ID
  static Future<String> cloneVoice({
    required String audioPath,
    required String prefix,
    required String targetModel,
    String? cloudAudioUrl,
  }) async {
    // 验证前缀格式
    if (!RegExp(r'^[a-z0-9]{1,9}$').hasMatch(prefix)) {
      throw Exception('前缀仅允许数字和小写字母，长度为1-9个字符');
    }

    // 验证目标模型
    if (targetModel != 'cosyvoice-v1' && targetModel != 'cosyvoice-v2') {
      throw Exception('目标模型仅支持cosyvoice-v1和cosyvoice-v2');
    }

    String audioUrl;

    // 如果提供了云端URL，直接使用
    if (cloudAudioUrl != null && cloudAudioUrl.isNotEmpty) {
      // 验证URL是否有效
      if (!cloudAudioUrl.startsWith('http://') &&
          !cloudAudioUrl.startsWith('https://')) {
        throw Exception('无效的云端音频URL，必须以 http:// 或 https:// 开头');
      }
      audioUrl = cloudAudioUrl;
    } else {
      // 没有提供云端URL，使用本地文件并上传到GitHub
      // 检查音频文件是否存在
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('音频文件不存在');
      }

      // 上传音频文件到可公开访问的URL
      audioUrl = await _uploadAudioFile(audioFile);
    }

    // 调用声音复刻API
    final headers = await _getHeaders();

    final requestBody = {
      // model 固定为voice-enrollment。
      "model": "voice-enrollment",
      "input": {
        // action 固定为create_voice。
        "action": "create_voice",
        // target_model 声音复刻所使用的模型，支持cosyvoice-v1和cosyvoice-v2。
        "target_model": targetModel,
        // prefix 自定义音色前缀，仅允许数字和小写字母，小于十个字符。
        "prefix": prefix,
        // 用于复刻音色的音频文件URL。该URL要求公网可访问。
        "url": audioUrl,
      },
    };

    try {
      final response = await HttpUtils.post(
        path: _cosyvoiceCloneBaseUrl,
        headers: headers,
        data: requestBody,
      );

      final responseData = response;

      // 响应示例
      /*
      {
        "output": {
            "voice_id": "yourVoiceId"
        },
        "usage": {
            "count": 1
        },
        "request_id": "yourRequestId"
      }
      */
      final String? voiceId = responseData?['output']?['voice_id'];

      if (voiceId == null || voiceId.isEmpty) {
        throw Exception('声音复刻失败：未能获取音色ID');
      }

      return voiceId;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('声音复刻失败：$e');
    }
  }

  /// 获取克隆的音色列表
  static Future<List<ClonedVoice>> getClonedVoices() async {
    final headers = await _getHeaders();

    try {
      final reqestBody = {
        "model": "voice-enrollment",
        "input": {
          "action": "list_voice",
          // 默认查询所有，就不过滤了
          // "prefix": "testpfx",
          "page_index": 0,
          "page_size": 1000,
        },
      };

      final response = await HttpUtils.post(
        path: _cosyvoiceCloneBaseUrl,
        headers: headers,
        data: reqestBody,
        showLoading: false,
      );

      /*
      // 响应示例
      {
          "output": {
              "voice_list": [
                  {
                      "gmt_create": "2024-12-11 13:38:02",
                      "voice_id": "yourVoiceId",
                      "gmt_modified": "2024-12-11 13:38:02",
                      "status": "OK"
                  }
              ]
          },
          "usage": {
              "count": 1
          },
          "request_id": "yourRequestId"
      }
      */
      final responseData = response;
      final List<dynamic> voiceList = responseData?['output']?['voice_list'];

      return List<ClonedVoice>.from(
        voiceList.map((voice) => ClonedVoice.fromJson(voice)),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('获取音色列表失败：$e');
    }
  }

  /// 更新克隆的音色
  static Future<void> updateClonedVoice(
    String voiceId,
    String audioPath,
  ) async {
    final headers = await _getHeaders();

    // 检查音频文件是否存在
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw Exception('音频文件不存在');
    }

    // 上传音频文件到可公开访问的URL
    final audioUrl = await _uploadAudioFile(audioFile);

    try {
      await HttpUtils.post(
        path: '$_cosyvoiceCloneBaseUrl/$voiceId',
        headers: headers,
        data: {
          "model": "voice-enrollment",
          "input": {
            "action": "update_voice",
            "voice_id": voiceId,
            "url": audioUrl,
          },
        },
      );
      // 更新音色的响应
      /*
        {
            "output": {},
            "usage": {
                "count": 1
            },
            "request_id": "yourRequestId"
        }
      */

      return;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('删除音色失败：$e');
    }
  }

  /// 删除克隆的音色
  static Future<void> deleteClonedVoice(String voiceId) async {
    final headers = await _getHeaders();

    try {
      await HttpUtils.post(
        path: '$_cosyvoiceCloneBaseUrl/$voiceId',
        headers: headers,
        data: {
          "model": "voice-enrollment",
          "input": {"action": "delete_voice", "voice_id": voiceId},
        },
      );

      return;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('删除音色失败：$e');
    }
  }

  /// 上传音频文件到临时存储服务，返回可公开访问的URL
  /// 使用GitHub存储服务进行上传
  static Future<String> _uploadAudioFile(File audioFile) async {
    try {
      // 从存储中获取GitHub配置
      final storage = CusGetStorage();
      final githubUsername = storage.getGithubUsername();
      final githubRepo = storage.getGithubRepo();
      final githubToken = storage.getGithubToken();

      // 检查GitHub配置是否存在
      if (githubUsername.isEmpty || githubRepo.isEmpty || githubToken.isEmpty) {
        throw Exception('未配置GitHub存储，请在设置中配置GitHub用户名、仓库名和访问令牌');
      }

      // 创建GitHub存储服务
      final githubStorage = GitHubStorageService(
        username: githubUsername,
        repoName: githubRepo,
        accessToken: githubToken,
        targetDirectory: 'voice_clone_audio',
      );

      // 验证GitHub凭证
      final isValid = await githubStorage.validateCredentials();
      if (!isValid) {
        throw Exception('GitHub凭证验证失败，请检查访问令牌是否有效');
      }

      // 确保目标目录存在
      await githubStorage.ensureDirectoryExists();

      // 上传文件并获取公开URL
      final fileUrl = await githubStorage.uploadFile(audioFile);

      return fileUrl;
    } catch (e) {
      throw Exception('上传音频文件失败：$e - 请确保GitHub配置正确');
    }
  }
}
