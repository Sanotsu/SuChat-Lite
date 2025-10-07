import 'package:sqflite/sqflite.dart';

import '../models/unified_platform_spec.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_conversation.dart';
import '../models/unified_chat_message.dart';
import '../models/unified_chat_partner.dart';
import 'unified_chat_db_init.dart';
import 'unified_chat_ddl.dart';

class UnifiedChatDao {
  // 单例模式
  static final UnifiedChatDao _dao = UnifiedChatDao._createInstance();
  // 构造函数，返回单例
  factory UnifiedChatDao() => _dao;

  // 命名的构造函数用于创建DatabaseHelper的实例
  UnifiedChatDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  final dbInit = UnifiedChatDBInit();

  /************************************
   * 对话相关
   ************************************/

  /// 保存对话
  Future<void> saveConversation(UnifiedConversation conversation) async {
    final db = await dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedConversation,
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入对话
  Future<List<int>> batchInsertConversationList(
    List<UnifiedConversation> items,
  ) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        UnifiedChatDdl.tableUnifiedConversation,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  /// 更新对话
  Future<int> updateConversation(UnifiedConversation conversation) async {
    final db = await dbInit.database;
    return await db.update(
      UnifiedChatDdl.tableUnifiedConversation,
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  /// 更新对话统计
  Future<void> updateConversationStats(String conversationId) async {
    final db = await dbInit.database;

    // 计算消息数量、总token和总成本
    final results = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as message_count,
        SUM(token_count) as total_tokens,
        SUM(cost) as total_cost
      FROM ${UnifiedChatDdl.tableUnifiedChatMessage}
      WHERE conversation_id = ? AND role != 'system'
    ''',
      [conversationId],
    );

    if (results.isNotEmpty) {
      final stats = results.first;
      await db.update(
        UnifiedChatDdl.tableUnifiedConversation,
        {
          'message_count': stats['message_count'] ?? 0,
          'total_tokens': stats['total_tokens'] ?? 0,
          'total_cost': stats['total_cost'] ?? 0.0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    }
  }

  // 获取单个对话
  Future<UnifiedConversation?> getConversation(String id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedConversation,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UnifiedConversation.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有对话
  Future<List<UnifiedConversation>> getConversations({
    // 为了简单，用户直接传入数据库可用的排序方式，栏位也需要是数据库需要的下划线连接的栏位
    List<String>? orderBy,
    // 对话可能太多，需要分页查询
    int? pageNumber,
    int? pageSize,
  }) async {
    // 如果用户有传入排序方式，先添加用户的排序方式，再添加默认的排序方式
    String orderByClause = 'updated_at DESC';
    if (orderBy != null) {
      orderByClause = '${orderBy.join(',')}, $orderByClause';
    }

    if (pageNumber != null && pageSize != null) {
      orderByClause =
          '$orderByClause LIMIT ${pageNumber * pageSize}, $pageSize';
    }

    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedConversation,
      orderBy: orderByClause,
    );

    return List.generate(maps.length, (i) {
      return UnifiedConversation.fromMap(maps[i]);
    });
  }

  // 删除对话
  Future<int> deleteConversation(String id) async {
    final db = await dbInit.database;
    return await db.delete(
      UnifiedChatDdl.tableUnifiedConversation,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /************************************
   * 消息相关
   ************************************/

  /// 保存消息
  Future<void> saveMessage(UnifiedChatMessage message) async {
    final db = await dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedChatMessage,
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新消息
  Future<int> updateMessage(UnifiedChatMessage message) async {
    final db = await dbInit.database;
    return await db.update(
      UnifiedChatDdl.tableUnifiedChatMessage,
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  /// 获取消息
  Future<UnifiedChatMessage?> getMessage(String id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedChatMessage,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UnifiedChatMessage.fromMap(maps.first);
    }
    return null;
  }

  /// 获取对话的消息列表
  Future<List<UnifiedChatMessage>> getMessagesByConversationId(
    String conversationId,
  ) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedChatMessage,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) {
      return UnifiedChatMessage.fromMap(maps[i]);
    });
  }

  /// 删除消息
  Future<void> deleteMessage(String id) async {
    final db = await dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedChatMessage,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除同一对话指定消息及其之后的消息
  Future<void> deleteMessageAndAfter(
    String conversationId,
    UnifiedChatMessage message,
  ) async {
    final db = await dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedChatMessage,
      where: 'conversation_id = ? AND created_at >= ?',
      whereArgs: [conversationId, message.createdAt.millisecondsSinceEpoch],
    );
  }

  // ==================== 聊天搭档相关操作 ====================

  /// 保存聊天搭档
  Future<void> saveChatPartner(UnifiedChatPartner partner) async {
    final db = await dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedChatPartner,
      partner.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取聊天搭档列表
  Future<List<UnifiedChatPartner>> getChatPartners({
    bool? isActive,
    bool? isBuiltIn,
    List<String>? orderBy,
  }) async {
    final db = await dbInit.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (isActive != null) {
      whereClause += 'is_active = ?';
      whereArgs.add(isActive ? 1 : 0);
    }

    if (isBuiltIn != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_built_in = ?';
      whereArgs.add(isBuiltIn ? 1 : 0);
    }

    String orderByClause = 'is_favorite DESC, created_at DESC';
    if (orderBy != null && orderBy.isNotEmpty) {
      orderByClause = '${orderBy.join(',')}, $orderByClause';
    }

    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedChatPartner,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderByClause,
    );

    return maps.map((map) => UnifiedChatPartner.fromMap(map)).toList();
  }

  /// 获取单个聊天搭档
  Future<UnifiedChatPartner?> getChatPartner(String id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedChatPartner,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UnifiedChatPartner.fromMap(maps.first);
    }
    return null;
  }

  /// 删除聊天搭档
  Future<void> deleteChatPartner(String id) async {
    final db = await dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedChatPartner,
      where: 'id = ? AND is_built_in = 0',
      whereArgs: [id],
    );
  }

  /// 切换搭档收藏状态
  Future<void> togglePartnerFavorite(String id) async {
    final partner = await getChatPartner(id);
    if (partner != null) {
      await saveChatPartner(
        partner.copyWith(
          isFavorite: !partner.isFavorite,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /************************************
   * 平台规格
   ************************************/

  /// 保存平台规格
  Future<void> savePlatformSpec(UnifiedPlatformSpec platformSpec) async {
    final db = await dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedPlatformSpec,
      platformSpec.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 重新加载内置平台
  Future<void> reloadBuiltInPlatforms() async {
    final db = await dbInit.database;
    await UnifiedChatDdl.initDefaultPlatforms(db);
    // TEST
    // await UnifiedChatDdl.initDefaultPartners(db);
  }

  /// 获取平台规格
  Future<UnifiedPlatformSpec?> getPlatformSpec(String id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedPlatformSpec,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UnifiedPlatformSpec.fromMap(maps.first);
    }
    return null;
  }

  /// 获取平台规格列表
  Future<List<UnifiedPlatformSpec>> getPlatformSpecs({
    String? name,
    bool? isActive,
  }) async {
    // 如果有传关键字搜索，才使用like和where
    String where = '1=1';
    List<String> whereArgs = [];
    if (name != null) {
      where = 'id LIKE ? or display_name LIKE ?';
      whereArgs = ['%$name%', '%$name%'];
    }

    if (isActive != null) {
      where = 'is_active = ?';
      whereArgs = [isActive ? '1' : '0'];
    }

    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedPlatformSpec,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_built_in DESC, display_name ASC',
    );
    return List.generate(maps.length, (i) {
      return UnifiedPlatformSpec.fromMap(maps[i]);
    });
  }

  /// 更新平台规格
  Future<void> updatePlatformSpec(UnifiedPlatformSpec platformSpec) async {
    final db = await dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedPlatformSpec,
      platformSpec.toMap(),
      where: 'id = ?',
      whereArgs: [platformSpec.id],
    );
  }

  /// 删除平台规格
  Future<void> deletePlatformSpec(String id) async {
    final db = await dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedPlatformSpec,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /************************************
   * 模型规格
   ************************************/

  /// 保存模型规格
  Future<void> saveModelSpec(UnifiedModelSpec modelSpec) async {
    final db = await dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedModelSpec,
      modelSpec.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新模型规格
  Future<void> updateModelSpec(UnifiedModelSpec modelSpec) async {
    final db = await dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedModelSpec,
      modelSpec.toMap(),
      where: 'id = ?',
      whereArgs: [modelSpec.id],
    );
  }

  /// 删除模型规格
  Future<void> deleteModelSpec(String id) async {
    final db = await dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除指定平台非内置模型
  Future<void> deleteNonBuiltInModelSpecs(String platformId) async {
    final db = await dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: 'platform_id = ? and is_built_in = 0',
      whereArgs: [platformId],
    );
  }

  /// 获取模型规格
  Future<UnifiedModelSpec?> getModelSpec(String id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UnifiedModelSpec.fromMap(maps.first);
    }
    return null;
  }

  /// 通过云平台编号获取模型列表
  Future<List<UnifiedModelSpec>> getModelSpecsByPlatformId(
    String platformId,
  ) async {
    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: 'platform_id = ?',
      whereArgs: [platformId],
    );
    return List.generate(maps.length, (i) {
      return UnifiedModelSpec.fromMap(maps[i]);
    });
  }

  /// 获取模型规格列表
  Future<List<UnifiedModelSpec>> getModelSpecs({
    String? name,
    List<String>? platformIds,
  }) async {
    // 如果有传关键字搜索，才使用like和where
    String where = '1=1';
    List<String> whereArgs = [];
    if (name != null) {
      where = 'name LIKE ?';
      whereArgs = ['%$name%'];
    }

    if (platformIds != null) {
      // 注意，平台id是字符串，所以要加引号
      where = 'platform_id IN (${platformIds.map((id) => '"$id"').join(",")})';
    }

    final db = await dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedModelSpec,
      where: where,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) {
      return UnifiedModelSpec.fromMap(maps[i]);
    });
  }
}
