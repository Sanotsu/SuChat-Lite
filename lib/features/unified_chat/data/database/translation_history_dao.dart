import 'unified_chat_db_init.dart';
import 'unified_chat_ddl.dart';

/// 翻译历史条目(2026-09-03 快速翻译新增)
class TranslationHistoryEntry {
  final int? id;
  final DateTime createdAt;
  final String sourceLang;
  final String targetLang;
  final String sourceText;
  final String translatedText;
  final String? modelName;
  final String? platformName;

  /// 语音合成生成的音频文件路径(合成成功后回写)
  final String? audioPath;

  const TranslationHistoryEntry({
    this.id,
    required this.createdAt,
    required this.sourceLang,
    required this.targetLang,
    required this.sourceText,
    required this.translatedText,
    this.modelName,
    this.platformName,
    this.audioPath,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'created_at': createdAt.toIso8601String(),
    'source_lang': sourceLang,
    'target_lang': targetLang,
    'source_text': sourceText,
    'translated_text': translatedText,
    'model_name': modelName,
    'platform_name': platformName,
    'audio_path': audioPath,
  };

  factory TranslationHistoryEntry.fromMap(Map<String, dynamic> map) =>
      TranslationHistoryEntry(
        id: map['id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        sourceLang: map['source_lang'] as String,
        targetLang: map['target_lang'] as String,
        sourceText: map['source_text'] as String,
        translatedText: map['translated_text'] as String,
        modelName: map['model_name'] as String?,
        platformName: map['platform_name'] as String?,
        audioPath: map['audio_path'] as String?,
      );
}

/// 翻译历史DAO(存于unified聊天库，随DB备份链自动备份)
class TranslationHistoryDao {
  static final TranslationHistoryDao _dao = TranslationHistoryDao._();
  factory TranslationHistoryDao() => _dao;
  TranslationHistoryDao._();

  final dbInit = UnifiedChatDBInit();

  Future<int> insert(TranslationHistoryEntry entry) async {
    final db = await dbInit.database;
    return await db.insert(
      UnifiedChatDdl.tableTranslationHistory,
      entry.toMap(),
    );
  }

  /// 按时间倒序查询
  Future<List<TranslationHistoryEntry>> query({int limit = 500}) async {
    final db = await dbInit.database;
    final rows = await db.query(
      UnifiedChatDdl.tableTranslationHistory,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(TranslationHistoryEntry.fromMap).toList();
  }

  /// 语音合成成功后回写音频路径
  Future<int> updateAudioPath(int id, String audioPath) async {
    final db = await dbInit.database;
    return await db.update(
      UnifiedChatDdl.tableTranslationHistory,
      {'audio_path': audioPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      UnifiedChatDdl.tableTranslationHistory,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clear() async {
    final db = await dbInit.database;
    return await db.delete(UnifiedChatDdl.tableTranslationHistory);
  }
}
