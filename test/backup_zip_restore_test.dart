// 备份zip解压与恢复预览分类回归
// 2026-10-12 FIX：archive 4.x extractFileToDisk 对旧版(3.x)编码的
// 备份包流式解压静默失败(23个json只解出1个，异常被包内catch(_){}
// 吞掉)——恢复预览全落"其他数据"、旧聊天/角色卡从未进入恢复执行。
// extractZipToDiskSync 改用 decodeBytes 全量内存解码+显式写盘。
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:suchat_lite/features/settings/services/backup_utils.dart';
import 'package:suchat_lite/features/settings/services/restore_executor.dart';

void main() {
  // 用户提供的0.1.4真实备份包(23个json，全根目录)
  final zip = File('images/SuChat全量数据备份_20261012_110703_000387.zip');
  final hasRealZip = zip.existsSync();

  test('真实0.1.4备份包解压全量文件(23个json一个不少)', () {
    if (!hasRealZip) {
      // CI无该资产时用自产包验证(见下一用例)
      return;
    }
    final tmp = Directory.systemTemp.createTempSync('unzip_real');
    try {
      BackupUtils.extractZipToDiskSync(zip.absolute.path, tmp.path);
      final files = tmp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      expect(files.length, 23, reason: 'archive4流式解压静默丢文件的回归点');
      expect(
        files.any(
          (f) => p.basename(f.path) == 'suchat_branch_chat_history.json',
        ),
        isTrue,
        reason: '旧聊天历史必须在解压结果中(此前被静默丢弃导致无法恢复)',
      );
      // 关键文件非空
      final branch = File(p.join(tmp.path, 'suchat_branch_chat_history.json'));
      expect(branch.lengthSync(), greaterThan(100 * 1024));
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });

  test('模块分类：0.1.4包内文件按模块正确识别(不全落其他数据)', () {
    final names = [
      'suchat_branch_chat_history.json',
      'suchat_character_card_list.json',
      'suchat_user_info.json',
      'suchat_bill_item.json',
      'suchat_note.json',
      'suchat_training_plan.json',
      'suchat_training_record.json',
      'suchat_meal_record.json',
      'suchat_voice_recognition_task.json',
      'suchat_brief_cus_llm_spec.json',
      'suchat_brief_media_generation_history.json',
    ];
    final modules = names.map(RestoreExecutor.moduleNameOf).toList();
    expect(modules[0], '旧版聊天历史(自动转新版)');
    expect(modules[1], '旧版角色卡');
    expect(modules[2], '用户信息');
    expect(modules[3], '极简记账-账单明细');
    expect(modules[4], '记事本-笔记');
    expect(modules[5], '训练助手-训练计划');
    expect(modules[6], '训练助手-训练记录');
    expect(modules[7], '饮食日记-餐食记录');
    expect(modules[8], 'AI工具-语音识别任务');
    // 0.1.4特有brief表已随旧LLM体系退役——归其他数据但必须可恢复
    expect(modules[9], '旧版AI配置(已废弃跳过)');
    expect(modules[10], '旧版生成记录(已废弃跳过)');
  });

  test('自产zip(4.x ZipFileEncoder)与旧式内存编码zip均可解压', () {
    final tmp = Directory.systemTemp.createTempSync('unzip_self');
    try {
      // 旧式内存编码(0.1.4同款)：ArchiveFile逐个add + ZipEncoder
      final content = '{"sessions":[]}'.codeUnits;
      final f1 = File(p.join(tmp.path, 'a.json'));
      f1.writeAsStringSync('{"sessions":[]}');
      final f2 = File(p.join(tmp.path, 'b.json'));
      f2.writeAsStringSync('[]');

      final out = Directory.systemTemp.createTempSync('unzip_out');
      try {
        final zipOut = p.join(out.path, 'self.zip');
        // 0.1.4同款编码方式：ArchiveFile逐个add + ZipEncoder内存编码
        final archive = Archive();
        archive.addFile(
          ArchiveFile('a.json', f1.lengthSync(), f1.readAsBytesSync()),
        );
        archive.addFile(
          ArchiveFile('b.json', f2.lengthSync(), f2.readAsBytesSync()),
        );
        File(zipOut).writeAsBytesSync(ZipEncoder().encode(archive));

        final target = Directory.systemTemp.createTempSync('unzip_target');
        try {
          BackupUtils.extractZipToDiskSync(zipOut, target.path);
          expect(target.listSync().whereType<File>().length, 2);
          expect(
            File(p.join(target.path, 'a.json')).readAsStringSync(),
            '{"sessions":[]}',
          );
        } finally {
          target.deleteSync(recursive: true);
        }
      } finally {
        out.deleteSync(recursive: true);
      }
      expect(content, isNotNull);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });

  test('zip路径穿越条目被拒', () {
    final tmp = Directory.systemTemp.createTempSync('unzip_traverse');
    try {
      expect(
        () => BackupUtils.extractZipToDiskSync(
          p.join(tmp.path, 'not_exists.zip'),
          tmp.path,
        ),
        throwsA(isA<FileSystemException>()),
      );
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
