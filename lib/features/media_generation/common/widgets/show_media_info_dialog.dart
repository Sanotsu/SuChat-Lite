import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../shared/constants/constants.dart';
import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/simple_tools.dart';

showMediaInfoDialog(AssetEntity entity, BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        // 修改默认弹窗的边距，可以让弹窗显示更宽一点
        // insetPadding: EdgeInsets.only(left: 10, right: 10),
        shape: RoundedRectangleBorder(
          // 设置圆角半径
          borderRadius: BorderRadius.circular(15),
        ),
        child: SizedBox(
          // 如果保持背景色为白色，圆角就看不到
          // color: Colors.white,
          height: 400,
          child: Column(
            children: [
              SizedBox(
                height: 50,
                child: Center(
                  child: Text("详情", style: TextStyle(fontSize: 20)),
                ),
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  itemExtent: 50,
                  children: <Widget>[
                    ListTile(
                      title: const Text("文件名称"),
                      subtitle: Text(
                        "${entity.title}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text("文件类型"),
                      subtitle: Text("${entity.mimeType}"),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text("文件路径"),
                      subtitle: Text(
                        "${entity.relativePath?.replaceAll("/storage/emulated/0", "内部存储")}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                    ),
                    ListTile(
                      title: const Text("修改时间"),
                      subtitle: Text(
                        DateFormat(
                          constDatetimeFormat,
                        ).format(entity.modifiedDateTime),
                      ),
                      dense: true,
                    ),
                    if (entity.type == AssetType.video)
                      ListTile(
                        title: const Text("视频时长"),
                        subtitle: Text(
                          formatDurationToString(entity.videoDuration),
                        ),
                        dense: true,
                      ),
                    if (entity.type == AssetType.audio)
                      ListTile(
                        title: const Text("音频时长"),
                        subtitle: Text(
                          formatDurationToString(
                            Duration(seconds: entity.duration),
                          ),
                        ),
                        dense: true,
                      ),
                    if (entity.type == AssetType.video ||
                        entity.type == AssetType.image)
                      ListTile(
                        title: const Text("文件尺寸"),
                        subtitle: Text(
                          "${entity.size.width.toInt()} x ${entity.size.height.toInt()}",
                        ),
                        dense: true,
                      ),
                    ListTile(
                      title: const Text("文件大小"),
                      subtitle: FutureBuilder<File?>(
                        future: entity.file,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<File?> snapshot,
                        ) {
                          // 其实分为hasData、hasError、加载中几个情况。
                          return (snapshot.hasData)
                              ? Text(
                                "${formatFileSize(snapshot.data?.statSync().size ?? 0, decimals: 2)} (${snapshot.data?.statSync().size} Byte)",
                              )
                              : const SizedBox();
                        },
                      ),
                      dense: true,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 60,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      child: const Text('确认'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
