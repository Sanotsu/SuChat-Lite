import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../common/utils/dio_client/cus_http_client.dart';
import '../models/brief_ai_tools/chat_completions/bigmodel_file_manage.dart';
import 'cus_get_storage.dart';

class BigmodelFileService {
  // 移除静态变量，改为每次都从存储中获取
  static String get _apikey => MyGetStorage().getBigmodelApiKey() ?? '';
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apikey',
  };

  /// 上传文件到智谱开放平台
  static Future<BigmodelFileUploadResult> uploadFilesToBigmodel(
    File file,
    String purpose, {
    String? knowledgeId,
  }) async {
    // 创建 FormData
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'purpose': 'file-extract',
    });

    try {
      final response = await HttpUtils.post(
        path: "https://open.bigmodel.cn/api/paas/v4/files",
        // 其他的是json，这个是formdata
        headers: {
          'Content-Type': 'multipart/form-data',
          'Authorization': 'Bearer $_apikey',
        },
        data: formData,
        showLoading: false,
        showErrorMessage: false,
      );

      // 理论上只有这个匹配，后面那个不会触发
      if (response != null && response is Map<String, dynamic>) {
        return BigmodelFileUploadResult.fromJson(response);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取智谱开放平台文件列表
  static Future<List<BigmodelGetFilesResult>> getFileListFromBigmodel(
    String purpose, {
    String? knowledgeId,
    String? after,
    String? order,
    int? limit,
    int? page,
  }) async {
    try {
      final response = await HttpUtils.get(
        path: "https://open.bigmodel.cn/api/paas/v4/files",
        headers: _headers,
        queryParameters: {'purpose': purpose, 'limit': 100, 'page': 1},
        showLoading: false,
        showErrorMessage: false,
      );

      // 理论上只有这个匹配，后面那个不会触发
      if (response != null && response is Map<String, dynamic>) {
        // 正常响应是取data属性了，不知道报错时怎样
        return (response['data'] as List<dynamic>)
            .map((e) => BigmodelGetFilesResult.fromJson(e))
            .toList();
      }

      // 理论上应该不会到这里来
      return BigmodelGetFilesResultResp.fromJson(json.decode(response)).data;
    } catch (e) {
      rethrow;
    }
  }

  /// 获取智谱开放平台文件列表
  static Future<BigmodelDeleteFilesResult> deleteFileFromBigmodel(
    String fileId,
  ) async {
    try {
      final response = await HttpUtils.delete(
        path: "https://open.bigmodel.cn/api/paas/v4/files/$fileId",
        headers: _headers,
        queryParameters: {'file_id': fileId},
        showLoading: false,
        showErrorMessage: false,
      );

      // 理论上只有这个匹配，后面那个不会触发
      if (response != null && response is Map<String, dynamic>) {
        return BigmodelDeleteFilesResult.fromJson(response);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 从智谱开放平台的文件中提取数据
  static Future<BigmodelExtractFileResult> getFileDataFromBigmodelFile(
    String fileId,
  ) async {
    try {
      final response = await HttpUtils.get(
        path: "https://open.bigmodel.cn/api/paas/v4/files/$fileId/content",
        headers: _headers,
        showLoading: false,
        showErrorMessage: false,
      );

      // 理论上只有这个匹配，后面两个不会触发
      if (response != null && response.runtimeType == String) {
        return BigmodelExtractFileResult.fromJson(json.decode(response));
      }

      if (response != null && response is Map<String, dynamic>) {
        return BigmodelExtractFileResult.fromJson(response);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
