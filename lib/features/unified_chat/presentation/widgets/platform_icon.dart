import 'package:flutter/material.dart';

import '../../../../shared/widgets/image_preview_helper.dart';
import '../../data/models/unified_platform_spec.dart';

Widget buildPlatformIcon(UnifiedPlatformSpec platform, {double size = 24}) {
  final iconPath = _getPlatformIcon(platform.id);

  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: SizedBox(
      width: size,
      height: size,
      child: iconPath.isNotEmpty
          ? buildNetworkOrFileImage(iconPath)
          : CircleAvatar(
              backgroundColor: Colors.grey,
              radius: size / 2,
              child: Text(
                platform.displayName.isNotEmpty == true
                    ? platform.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
    ),
  );
}

// 根据平台获取本地图标
String _getPlatformIcon(String platformId) {
  const commonIcon = 'assets/platform_icons/small/';
  switch (platformId) {
    case 'lingyiwanwu':
      return '${commonIcon}lingyiwanwu.png';
    case 'deepseek':
      return '${commonIcon}deepseek.png';
    case 'zhipu':
      return '${commonIcon}zhipu.png';
    case 'baidu':
      return '${commonIcon}baidu.png';
    case 'volcengine':
    case 'volcesBot':
      return '${commonIcon}volcengine.png';
    case 'tencent':
      return '${commonIcon}tencent.png';
    case 'aliyun':
      return '${commonIcon}aliyun.png';
    case 'siliconCloud':
      return '${commonIcon}siliconcloud.png';
    case 'infini':
      return '${commonIcon}infini.png';
    default:
      return '';
  }
}
