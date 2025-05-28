import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import '../../core/network/dio_client/cus_http_client.dart';

/// GitHub存储服务
/// 将文件上传到GitHub仓库并获取公开访问地址
class GitHubStorageService {
  // GitHub API基础URL
  static const String _baseApiUrl = 'https://api.github.com';

  // 用户配置
  final String username;
  final String repoName;
  final String branch;
  final String accessToken;

  // 目标存储目录
  final String targetDirectory;

  GitHubStorageService({
    required this.username,
    required this.repoName,
    required this.accessToken,
    this.branch = 'main',
    this.targetDirectory = 'audio_files',
  });

  /// 获取授权头
  Map<String, dynamic> get _authHeaders {
    return {
      'Authorization': 'token $accessToken',
      'Accept': 'application/vnd.github.v3+json',
    };
  }

  /// 上传文件到GitHub仓库
  /// 返回公开访问的URL
  Future<String> uploadFile(File file) async {
    try {
      // 使用原始文件名，不带时间戳
      final baseName = path.basename(file.path);

      // 确保文件名安全，移除不安全字符
      final safeBaseName = baseName
          .replaceAll(RegExp(r'[^\w\s\.\-]'), '') // 只保留字母、数字、空格、点和连字符
          .replaceAll(RegExp(r'\s+'), '_'); // 空格替换为下划线

      // 读取文件内容并计算内容hash作为唯一标识
      final fileContent = await file.readAsBytes();
      // 取内容hash的前8位作为文件名前缀，保证相同内容的文件有相同的名字
      final contentHash = base64Encode(
        fileContent,
      ).hashCode.toRadixString(16).padLeft(8, '0').substring(0, 8);
      final fileName = '${contentHash}_$safeBaseName';
      final filePath = '$targetDirectory/$fileName';

      // 检查目录中是否有相同hash开头的文件
      try {
        // 先获取目录内容
        final directoryResponse = await HttpUtils.get(
          path:
              '$_baseApiUrl/repos/$username/$repoName/contents/$targetDirectory',
          headers: _authHeaders,
          showLoading: false,
          showErrorMessage: false,
        );

        // 目录存在，检查是否有相同hash前缀的文件
        if (directoryResponse != null && directoryResponse is List) {
          for (final item in directoryResponse) {
            final existingFileName = item['name'];
            // 检查文件是否有相同的hash前缀（相同内容的文件）
            if (existingFileName.startsWith('${contentHash}_')) {
              final existingFilePath = '$targetDirectory/$existingFileName';
              final rawUrl =
                  'https://raw.githubusercontent.com/$username/$repoName/$branch/$existingFilePath';
              debugPrint('发现相同内容的文件，直接返回URL: $rawUrl');
              return rawUrl;
            }
          }
        }
      } catch (e) {
        // 目录不存在或获取失败，继续上传流程
        debugPrint('检查目录内容失败，准备上传新文件: $e');
      }

      final base64Content = base64Encode(fileContent);

      // 准备请求数据
      final requestData = {
        'message': 'Upload audio file: $fileName',
        'content': base64Content,
        'branch': branch,
      };

      // 发送创建文件请求
      // final response = await HttpUtils.put(xxx)
      // print("github uploadFile 的响应:$response");
      // await HttpUtils.put(
      //   path: '$_baseApiUrl/repos/$username/$repoName/contents/$filePath',
      //   headers: _authHeaders,
      //   data: requestData,
      //   showLoading: false,
      //   showErrorMessage: true,
      // );

      // 使用 HttpUtils 有设置默认超时1分钟，文件过大上传到github可能不止1分钟
      await Dio().put(
        '$_baseApiUrl/repos/$username/$repoName/contents/$filePath',
        data: requestData,
        options: Options(headers: _authHeaders),
      );

      // 获取并返回文件的公开访问URL
      // GitHub Raw URL格式: https://raw.githubusercontent.com/{username}/{repoName}/{branch}/{filePath}
      final rawUrl =
          'https://raw.githubusercontent.com/$username/$repoName/$branch/$filePath';

      debugPrint('文件已上传到GitHub: $rawUrl');
      return rawUrl;
    } catch (e) {
      debugPrint('上传文件到GitHub失败: $e');
      throw Exception('上传文件到GitHub失败: $e');
    }
  }

  /// 检查GitHub仓库是否存在目标目录
  /// 如果不存在，可以创建该目录（通过创建一个.gitkeep文件）
  Future<bool> ensureDirectoryExists() async {
    try {
      // 检查目录是否存在
      try {
        await HttpUtils.get(
          path:
              '$_baseApiUrl/repos/$username/$repoName/contents/$targetDirectory',
          headers: _authHeaders,
          showLoading: false,
          showErrorMessage: false,
        );
        // 如果成功返回，说明目录存在
        return true;
      } catch (e) {
        // 如果请求失败，可能是目录不存在，尝试创建目录
        debugPrint('目录不存在，尝试创建: $targetDirectory');

        // 创建一个.gitkeep文件来创建目录
        final requestData = {
          'message': 'Create directory: $targetDirectory',
          'content': '', // 空内容
          'branch': branch,
        };

        await HttpUtils.put(
          path:
              '$_baseApiUrl/repos/$username/$repoName/contents/$targetDirectory/.gitkeep',
          headers: _authHeaders,
          data: requestData,
          contentType: 'application/json',
          showLoading: false,
          showErrorMessage: true,
        );

        return true;
      }
    } catch (e) {
      debugPrint('检查/创建GitHub目录失败: $e');
      return false;
    }
  }

  /// 验证GitHub API访问凭证
  Future<bool> validateCredentials() async {
    try {
      // 尝试获取用户信息，验证访问凭证
      await HttpUtils.get(
        path: '$_baseApiUrl/user',
        headers: _authHeaders,
        showLoading: false,
        showErrorMessage: false,
      );
      return true;
    } catch (e) {
      debugPrint('GitHub API凭证验证失败: $e');
      return false;
    }
  }
}
