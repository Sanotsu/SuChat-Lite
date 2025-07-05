// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/entities/user_info.dart';
import '../../../core/storage/db_config.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../../../core/storage/ddl_notebook.dart';
import '../../../core/storage/ddl_simple_accounting.dart';
import '../../../core/storage/ddl_training.dart';
import '../../../core/utils/datetime_formatter.dart';
import '../../../shared/widgets/toast_utils.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../../core/entities/cus_llm_model.dart';
import '../../../core/storage/db_helper.dart';
import '../../../core/storage/db_ddl.dart';
import '../../../core/storage/db_init.dart';
import '../../../core/utils/file_picker_utils.dart';
import '../../../core/utils/screen_helper.dart';
import '../../../core/utils/simple_tools.dart';
import '../../branch_chat/data/models/branch_chat_export_data.dart';
import '../../branch_chat/presentation/viewmodels/branch_store.dart';
import '../../branch_chat/presentation/viewmodels/character_store.dart';
import '../../diet_diary/data/index.dart';
import '../../diet_diary/domain/entities/index.dart';
import '../../media_generation/common/entities/media_generation_history.dart';
import '../../notebook/data/note_dao.dart';
import '../../notebook/domain/entities/index.dart';
import '../../simple_accounting/data/bill_dao.dart';
import '../../simple_accounting/domain/entities/bill_category.dart';
import '../../simple_accounting/domain/entities/bill_item.dart';
import '../../training_assistant/data/training_dao.dart';
import '../../training_assistant/domain/entities/index.dart';
import '../../voice_recognition/domain/entities/voice_recognition_task_info.dart';

///
/// 2023-12-26 备份恢复还可以优化，就暂时不做
///
///
// 全量备份导出的文件的前缀(_时间戳.zip)
const ZIP_FILE_PREFIX = "SuChat全量数据备份_";
// 导出文件要压缩，临时存放的地址
const ZIP_TEMP_DIR_AT_EXPORT = "temp_zip";
const ZIP_TEMP_DIR_AT_UNZIP = "temp_de_zip";
const ZIP_TEMP_DIR_AT_RESTORE = "temp_auto_zip";

// 角色列表和分支会话的文件名
const CHARACTER_CARD_LIST_FILE_NAME = 'suchat_character_card_list.json';
const BRANCH_CHAT_HISTORY_FILE_NAME = 'suchat_branch_chat_history.json';

class BackupAndRestorePage extends StatefulWidget {
  // 主页面有获取，直接传入，不要再次获取
  final String packageVersion;

  const BackupAndRestorePage({super.key, required this.packageVersion});

  @override
  State<BackupAndRestorePage> createState() => _BackupAndRestorePageState();
}

class _BackupAndRestorePageState extends State<BackupAndRestorePage> {
  final DBHelper _dbHelper = DBHelper();
  final DBInit _dbInit = DBInit();

  bool isLoading = false;

  // 是否获得了存储权限(没获得就无法备份恢复)
  bool isPermissionGranted = false;

  String note = """**全量备份** 是把应用本地数据库中的所有数据导出保存在本地，包括用智能助手的对话历史、账单列表、菜品列表。
\n\n**覆写恢复** 是把 '全量备份' 导出的压缩包，重新导入到应用中，覆盖应用本地数据库中的所有数据。""";

  @override
  void initState() {
    super.initState();

    _getPermission();
  }

  Future<void> _getPermission() async {
    bool flag = await requestStoragePermission();
    setState(() {
      isPermissionGranted = flag;
    });
  }

  ///
  /// 全量备份：导出db中所有的数据
  ///
  /// 1. 询问是否有范围内部存储的权限
  /// 2. 用户选择要导出的文件存放的位置
  /// 3. 处理备份
  ///   3.1 先创建一个内部临时保存备份文件的地址
  ///          不直接保存到用户指定地址，是避免万一导出很久还没完用户就删掉了，整个过程就无法控制
  ///   3.2 dbhelper导出table数据为各个json文件
  ///   3.3 将这些json文件压缩到各个创建的内部临时地址
  ///   3.4 将临时地址的压缩文件，复制到用户指定的文件
  ///   3.5 删除临时地址的压缩文件
  ///
  Future<void> exportAllData() async {
    // 用户没有授权，简单提示一下
    if (!mounted) return;
    if (!isPermissionGranted) {
      ToastUtils.showError(
        "用户已禁止访问内部存储,无法进行json文件导入。\n如需启用，请到应用的权限管理中授权读写手机存储。",
      );
      return;
    }

    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // 如果有选中文件夹，执行导出数据库的json文件，并添加到压缩档。
    if (selectedDirectory != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 获取应用文档目录路径
      // 这个获取缓存目录即可
      Directory tempDir = await getTemporaryDirectory();
      // 临时存放zip文件的路径
      var tempZipDir =
          await Directory(
            p.join(tempDir.path, ZIP_TEMP_DIR_AT_EXPORT),
          ).create();
      // zip 文件的名称
      String zipName = "$ZIP_FILE_PREFIX${fileTs(DateTime.now())}.zip";

      try {
        // 执行将db数据导出到临时json路径和构建临时zip文件(？？？应该有错误检查)
        await _backupDbData(zipName, tempZipDir.path);

        // 移动临时文件到用户选择的位置
        File sourceFile = File(p.join(tempZipDir.path, zipName));
        File destinationFile = File(p.join(selectedDirectory, zipName));

        // 如果目标文件已经存在，则先删除
        if (destinationFile.existsSync()) {
          destinationFile.deleteSync();
        }

        // 把文件从缓存的位置放到用户选择的位置
        sourceFile.copySync(p.join(selectedDirectory, zipName));
        debugPrint('文件已成功复制到：${p.join(selectedDirectory, zipName)}');

        // 删除临时zip文件
        if (sourceFile.existsSync()) {
          // 如果目标文件已经存在，则先删除
          sourceFile.deleteSync();
        }

        setState(() {
          isLoading = false;
        });

        ToastUtils.showSuccess("已经保存到$selectedDirectory");
      } catch (e) {
        debugPrint('保存操作出现错误: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      debugPrint('保存操作已取消');
      return;
    }
  }

  /// 备份db中数据到指定文件夹
  /// zipName: 会把所有json文件打包成1个压缩包，这是压缩包的名称
  /// tempZipPath: 在构建zip文件时，会先放到临时文件夹，构建完成后才复制到用户指定的路径去
  Future<void> _backupDbData(String zipName, String tempZipPath) async {
    // 导出数据库
    await _dbInit.exportDatabase();

    // 创建或检索压缩包临时存放的文件夹
    var tempZipDir = await Directory(tempZipPath).create();

    // 获取临时文件夹目录
    Directory appDocDir = await getApplicationCacheDirectory();
    String tempJsonsPath = p.join(appDocDir.path, DBInitConfig.exportDir);
    // 临时存放所有json文件的文件夹
    Directory tempDirectory = Directory(tempJsonsPath);

    /// 非sqlite的高级助手使用的objectbox和角色扮演使用的json文件，也在这里静默导出
    await _handleBranchChatExport(tempDirectory);
    await _handleCharacterExport(tempDirectory);

    // 创建Archive对象
    final archive = Archive();

    // 遍历临时文件夹中的所有文件和子文件夹，并将它们添加到archive中
    await for (FileSystemEntity entity in tempDirectory.list(recursive: true)) {
      if (entity is File) {
        // 读取文件内容
        final bytes = await entity.readAsBytes();
        // 获取相对路径（相对于tempJsonsPath）
        final relativePath = p.relative(entity.path, from: tempJsonsPath);
        // 添加到archive
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    // 使用ZipEncoder编码archive为zip文件
    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);

    // 写入zip文件
    final zipFile = File(p.join(tempZipDir.path, zipName));
    await zipFile.writeAsBytes(zipBytes);

    // 压缩完成后，清空临时json文件夹中文件
    await _deleteFilesInDirectory(tempJsonsPath);
  }

  Future<void> _handleBranchChatExport(Directory tempDirectory) async {
    try {
      // 1. 获取所有会话数据
      final store = await BranchStore.create();
      final sessions = store.sessionBox.getAll();

      // 2. 转换为导出格式
      final exportData = BranchChatExportData(
        sessions:
            sessions
                .map((session) => BranchChatSessionExport.fromSession(session))
                .toList(),
      );

      // 3. 在指定目录创建文件
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}$BRANCH_CHAT_HISTORY_FILE_NAME',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData.toJson()),
      );
    } catch (e) {
      debugPrint('导出高级助手会话数据出错: $e');
    }
  }

  Future<void> _handleCharacterExport(Directory tempDirectory) async {
    try {
      final store = await CharacterStore.create();

      // 只导出非系统角色
      final cardJsonList =
          store.characters
              .where((c) => !c.isSystem)
              .map((c) => c.toJson())
              .toList();

      final cardFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}$CHARACTER_CARD_LIST_FILE_NAME',
      );

      await cardFile.writeAsString(jsonEncode(cardJsonList));
    } catch (e) {
      debugPrint('导出角色列表数据出错: $e');
    }
  }

  // 删除指定文件夹下所有文件
  Future<void> _deleteFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await for (var file in directory.list()) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  ///
  /// 2023-12-11 恢复的话，简单需要导出时同名的zip压缩包
  ///
  /// 1. 获取用户选择的压缩文件
  /// 2. 判断选中的文件是否符合导出的文件格式(匹配前缀和后缀，不符合不做任何操作)
  /// 3. 处理导入过程
  ///   3.1 先解压压缩包，读取json文件
  ///   3.2 先将数据库中的数据备份到临时文件夹中(避免恢复失败数据就找不回来了)
  ///   3.3 临时备份完成，删除数据库，再新建数据库(插入时会自动新建)
  ///   3.4 将json文件依次导入数据库
  ///   3.5 json文件导入成功，则删除临时备份文件
  ///
  Future<void> restoreDataFromBackup() async {
    File? file = await FilePickerUtils.pickAndSaveFile(
      fileType: CusFileType.custom,
      // 导出时指定为zip，所以这里也限制为zip
      allowedExtensions: ['zip'],
    );

    if (file != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      debugPrint("获取的上传zip文件路径：${p.basename(file.path)}");

      // 这个判断虽然不准确，但先这样
      if (p.basename(file.path).startsWith(ZIP_FILE_PREFIX) &&
          p.basename(file.path).toLowerCase().endsWith('.zip')) {
        try {
          // 创建临时目录用于解压
          Directory tempDir = await getTemporaryDirectory();
          String unzipPath = p.join(tempDir.path, ZIP_TEMP_DIR_AT_UNZIP);

          // 先清空临时目录避免旧解压文件残留
          await _deleteFilesInDirectory(unzipPath);

          // 使用extractFileToDisk替代手动解压，简化代码
          await extractFileToDisk(file.path, unzipPath);

          // 获取解压后的JSON文件
          List<File> jsonFiles =
              Directory(unzipPath)
                  .listSync()
                  .where(
                    (entity) => entity is File && entity.path.endsWith('.json'),
                  )
                  .map((entity) => entity as File)
                  .toList();

          debugPrint("解压得到的jsonFiles：$jsonFiles");

          /// 删除前可以先备份一下到临时文件，避免出错后完成无法使用(最多确认恢复成功之后再删除就好了)
          // 临时存放zip文件的路径
          var tempZipDir =
              await Directory(
                p.join(tempDir.path, ZIP_TEMP_DIR_AT_RESTORE),
              ).create();
          // zip 文件的名称
          String zipName = "$ZIP_FILE_PREFIX${fileTs(DateTime.now())}.zip";
          // 执行将db数据导出到临时json路径和构建临时zip文件(？？？应该有错误检查)
          await _backupDbData(zipName, tempZipDir.path);

          // 恢复旧数据之前，删除现有数据库
          await _dbInit.deleteDB();

          // 保存恢复的数据(应该检查的？？？)
          await _saveJsonFileDataToDb(jsonFiles);

          // 成功恢复后，删除临时备份的zip
          File sourceFile = File(p.join(tempZipDir.path, zipName));
          // 删除临时zip文件
          if (sourceFile.existsSync()) {
            // 如果目标文件已经存在，则先删除
            sourceFile.deleteSync();
          }

          // 还要删除解压的临时文件
          await _deleteFilesInDirectory(unzipPath);

          setState(() {
            isLoading = false;
          });

          ToastUtils.showSuccess("原有数据已删除，备份数据已恢复。");
        } catch (e) {
          // rethrow;
          // 弹出报错提示框
          if (!mounted) return;

          commonHintDialog(
            context,
            "导入json文件出错",
            "文件名称:\n${file.path}\n\n错误信息:\n${e.toString()}",
          );

          setState(() {
            isLoading = false;
          });
          // 中止操作
          return;
        }
      } else {
        ToastUtils.showError("用于恢复的备份文件格式不对，恢复已取消。");
      }
      // 这个判断不准确，但先这样
      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 将恢复的json数据存入db中
  Future<void> _saveJsonFileDataToDb(List<File> jsonFiles) async {
    // 解压之后获取到所有的json文件，逐个添加到数据库，会先清空数据库的数据
    for (File file in jsonFiles) {
      // 获取文件名
      var filename = p.basename(file.path).toLowerCase();

      debugPrint("执行json保存到db时对应的json文件：${file.path} 文件名：$filename");

      // 2025-03-26 这里是角色会话和分支会话的还原
      if (filename == BRANCH_CHAT_HISTORY_FILE_NAME) {
        final store = await BranchStore.create();
        await store.importSessionHistory(file);
        continue;
      }

      if (filename == CHARACTER_CARD_LIST_FILE_NAME) {
        final store = await CharacterStore.create();
        await store.importCharacters(file.path);
        continue;
      }

      // 读取json文件内容
      String jsonData = await file.readAsString();
      // db导出时json文件是列表
      // 2025-03-26 分支对话的json文件是对象
      List jsonMapList = json.decode(jsonData);

      // 根据不同文件名，构建不同的数据

      /// 智能助手基本表
      if (filename == "${DBDdl.tableCusLlmSpec}.json") {
        await _dbHelper.saveCusLLMSpecs(
          jsonMapList.map((e) => CusLLMSpec.fromMap(e)).toList(),
        );
      } else if (filename == "${DBDdl.tableMediaGenerationHistory}.json") {
        await _dbHelper.saveMediaGenerationHistories(
          jsonMapList.map((e) => MediaGenerationHistory.fromMap(e)).toList(),
        );
      } else if (filename == "${DBDdl.tableVoiceRecognitionTask}.json") {
        await _dbHelper.saveVoiceRecognitionTasks(
          jsonMapList.map((e) => VoiceRecognitionTaskInfo.fromMap(e)).toList(),
        );
      }
      /// 用户信息
      else if (filename == "${DBDdl.tableUserInfo}.json") {
        await _dbHelper.batchInsert(
          jsonMapList.map((e) => UserInfo.fromMap(e)).toList(),
        );
      }
      /// 训练助手
      else if (filename == "${TrainingDdl.tableTrainingPlan}.json") {
        await TrainingDao().insertTrainingPlans(
          jsonMapList.map((e) => TrainingPlan.fromMap(e)).toList(),
        );
      } else if (filename == "${TrainingDdl.tableTrainingPlanDetail}.json") {
        await TrainingDao().insertTrainingPlanDetails(
          jsonMapList.map((e) => TrainingPlanDetail.fromMap(e)).toList(),
        );
      } else if (filename == "${TrainingDdl.tableTrainingRecord}.json") {
        await TrainingDao().insertTrainingRecords(
          jsonMapList.map((e) => TrainingRecord.fromMap(e)).toList(),
        );
      } else if (filename == "${TrainingDdl.tableTrainingRecordDetail}.json") {
        await TrainingDao().insertTrainingRecordDetails(
          jsonMapList.map((e) => TrainingRecordDetail.fromMap(e)).toList(),
        );
      }
      /// 饮食日记
      else if (filename == "${DietDiaryDdl.tableDietAnalysis}.json") {
        await DietAnalysisDao().batchInsert(
          jsonMapList.map((e) => DietAnalysis.fromMap(e)).toList(),
        );
      } else if (filename == "${DietDiaryDdl.tableDietRecipe}.json") {
        await DietRecipeDao().batchInsert(
          jsonMapList.map((e) => DietRecipe.fromMap(e)).toList(),
        );
      } else if (filename == "${DietDiaryDdl.tableFoodItem}.json") {
        await FoodItemDao().batchInsert(
          jsonMapList.map((e) => FoodItem.fromMap(e)).toList(),
        );
      } else if (filename == "${DietDiaryDdl.tableMealFoodRecord}.json") {
        await MealFoodRecordDao().batchInsert(
          jsonMapList.map((e) => MealFoodRecord.fromMap(e)).toList(),
        );
      } else if (filename == "${DietDiaryDdl.tableMealRecord}.json") {
        await MealRecordDao().batchInsert(
          jsonMapList.map((e) => MealRecord.fromMap(e)).toList(),
        );
      } else if (filename == "${DietDiaryDdl.tableWeightRecord}.json") {
        await WeightRecordDao().batchInsert(
          jsonMapList.map((e) => WeightRecord.fromMap(e)).toList(),
        );
      }
      /// 极简记账
      else if (filename == "${SimpleAccountingDdl.tableBillCategory}.json") {
        await BillDao().batchInsertCategory(
          jsonMapList.map((e) => BillCategory.fromMap(e)).toList(),
        );
      } else if (filename == "${SimpleAccountingDdl.tableBillItem}.json") {
        await BillDao().batchInsertBillItem(
          jsonMapList.map((e) => BillItem.fromMap(e)).toList(),
        );
      }
      /// 记事本
      else if (filename == "${NotebookDdl.tableNoteCategory}.json") {
        await NoteDao().batchCreateCategory(
          jsonMapList.map((e) => NoteCategory.fromMap(e)).toList(),
        );
      } else if (filename == "${NotebookDdl.tableNoteTag}.json") {
        await NoteDao().batchCreateTag(
          jsonMapList.map((e) => NoteTag.fromMap(e)).toList(),
        );
      } else if (filename == "${NotebookDdl.tableNoteMedia}.json") {
        await NoteDao().batchCreateMedia(
          jsonMapList.map((e) => NoteMedia.fromMap(e)).toList(),
        );
      } else if (filename == "${NotebookDdl.tableNote}.json") {
        await NoteDao().batchCreateNote(
          jsonMapList.map((e) => Note.fromMap(e)).toList(),
        );
      } else if (filename == "${NotebookDdl.tableNoteTagRelation}.json") {
        await NoteDao().batchCreateNoteTagRelation(jsonMapList);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("备份恢复"),
        actions: [
          IconButton(
            onPressed: () {
              commonMarkdwonHintDialog(
                context,
                "备份恢复说明",
                note,
                msgFontSize: 15,
              );
            },
            icon: const Icon(Icons.info_outline),
            tooltip: '帮助',
          ),
        ],
      ),
      body:
          isLoading
              ? buildLoader(isLoading)
              : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 40),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildBackupCard(),
                              SizedBox(width: 20),
                              _buildRestoreCard(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildInfoSection(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Icon(
          Icons.import_export,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          "数据备份与恢复",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "保护您的数据安全，随时备份和恢复",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackupCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showBackupConfirmationDialog();
        },
        child: Padding(
          padding: EdgeInsets.all(ScreenHelper.isDesktop() ? 32 : 16.0),
          child: Column(
            children: [
              Icon(Icons.backup, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                "全量备份",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (ScreenHelper.isDesktop())
                Text(
                  "导出所有数据到备份文件",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text(
                  "立即备份",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () {
                  _showBackupConfirmationDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: restoreDataFromBackup,
        child: Padding(
          padding: EdgeInsets.all(ScreenHelper.isDesktop() ? 32 : 16.0),
          child: Column(
            children: [
              Icon(Icons.restore, size: 40, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                "覆写恢复",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (ScreenHelper.isDesktop())
                Text(
                  "从备份文件恢复所有数据",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  "选择文件",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: restoreDataFromBackup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        const Text(
          "温馨提示",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "1. 定期备份可防止数据丢失\n"
          "2. 恢复操作将覆盖现有数据\n",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showBackupConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("全量备份"),
          content: const Text("确认导出所有数据到备份文件？"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context, false);
              },
              child: const Text("取消"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text("确认备份"),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value) exportAllData();
    });
  }
}
