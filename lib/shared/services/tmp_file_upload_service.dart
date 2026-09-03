import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/dio_client/cus_http_client.dart';

/// 临时文件上传服务
/// 上传本地文件到 tmpfile.link(tfLink) 换取公网直链(无需注册，匿名保存7天)
/// 2026-09-03 自tmpfiles.org迁移：tmpfiles.org的API返回的是网页地址
/// (页面包装+Cloudflare防护)，DashScope等服务端直接下载会得到HTML报
/// FILE_DOWNLOAD_FAILED；tfLink的API响应直接给出下载直链(d.tmpfile.link
/// 专用下载域名)，无页面包装，文档：https://tmpfile.link/index-zh
class TmpFileUploadService {
  /// 上传文件，返回可直接下载的直链
  /// [maxSizeMB] 文件大小上限(MB)，服务上限100M
  static Future<String> upload(File file, {double maxSizeMB = 100.0}) async {
    if (!file.existsSync()) {
      throw Exception('文件不存在: ${file.path}');
    }

    final sizeMB = file.lengthSync() / (1024 * 1024);
    if (sizeMB > maxSizeMB) {
      throw Exception(
        '文件大小 ${sizeMB.toStringAsFixed(1)}MB 超过限制 ${maxSizeMB}MB',
      );
    }

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'file',
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      ),
    );

    final response = await HttpUtils.post(
      path: 'https://tmpfile.link/api/upload',
      data: formData,
    );

    // 响应示例：
    // {
    //   "fileName": "xx.mp3",
    //   "downloadLink": "https://d.tmpfile.link/public/2025-07-31/{uuid}/xx.mp3",
    //   "downloadLinkEncoded": "https://d.tmpfile.link/public/.../%E4%B8%AD%E6%96%87.mp3",
    //   "size": 102400, "type": "audio/mpeg", "uploadedTo": "public"
    // }
    // 优先取URL编码版链接(文件名含中文/空格时更稳)
    final encoded = response?['downloadLinkEncoded'] as String?;
    final plain = response?['downloadLink'] as String?;
    final downloadLink = (encoded != null && encoded.isNotEmpty)
        ? encoded
        : plain;

    if (downloadLink == null || downloadLink.isEmpty) {
      throw Exception('无法获取上传到tmpfile.link的下载地址。\nresponse:$response');
    }

    return downloadLink;
  }
}
