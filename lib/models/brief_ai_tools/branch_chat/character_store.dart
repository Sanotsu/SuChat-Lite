import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../common/utils/tools.dart';
import '../../../objectbox.g.dart';
import '../../../common/components/toast_utils.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import 'character_card.dart';

class CharacterStore {
  // 单例模式
  static CharacterStore? _instance;

  // ObjectBox 存储实例
  late final Store store;

  // 角色卡 Box
  late final Box<CharacterCard> characterBox;

  // 私有构造函数
  CharacterStore._create();

  // 创建单例实例
  static Future<CharacterStore> create() async {
    if (_instance != null) return _instance!;

    final instance = CharacterStore._create();
    await instance._init();
    _instance = instance;
    return instance;
  }

  // 初始化 ObjectBox
  Future<void> _init() async {
    try {
      final docsDir = await getAppHomeDirectory();
      final dbDirectory = p.join(docsDir.path, "objectbox", "characters");

      // 确保目录存在
      final dir = Directory(dbDirectory);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      store = await openStore(directory: dbDirectory);
      characterBox = store.box<CharacterCard>();

      // 检查数据库中是否有角色
      // 系统角色可删除，但如果没有用户自定义的，会重新创建
      if (characterBox.isEmpty()) {
        await _createDefaultCharacters();
      }
    } catch (e) {
      pl.e('初始化 ObjectBox 失败: $e');
      rethrow;
    }
  }

  // 获取所有角色卡
  List<CharacterCard> get characters {
    return characterBox.getAll();
  }

  // 根据ID获取角色卡
  CharacterCard? getCharacterById(String characterId) {
    final query =
        characterBox
            .query(CharacterCard_.characterId.equals(characterId))
            .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  // 创建新角色卡
  Future<CharacterCard> createCharacter(CharacterCard character) async {
    final id = characterBox.put(character);
    return characterBox.get(id)!;
  }

  // 更新角色卡
  Future<CharacterCard> updateCharacter(CharacterCard character) async {
    character.updateTime = DateTime.now();
    final id = characterBox.put(character);
    return characterBox.get(id)!;
  }

  // 删除角色卡
  Future<bool> deleteCharacter(String characterId) async {
    final query =
        characterBox
            .query(CharacterCard_.characterId.equals(characterId))
            .build();
    final character = query.findFirst();
    query.close();

    if (character != null) {
      characterBox.remove(character.id);
      return true;
    }
    return false;
  }

  // 创建默认角色卡
  Future<void> _createDefaultCharacters() async {
    // 创建工具角色
    await _createToolCharacters();

    // 创建虚拟角色
    await _createVirtualCharacters();
  }

  // 创建系统默认角色
  Future<CharacterCard> _createDefaultCharacter({
    required String characterId,
    required String name,
    required String avatar,
    required String description,
    String personality = '',
    String scenario = '',
    String firstMessage = '',
    String exampleDialogue = '',
    List<String>? tags,
    CusBriefLLMSpec? preferredModel,
    bool isSystem = false,
    String? background,
    double? backgroundOpacity,
  }) async {
    final character = CharacterCard(
      characterId: characterId,
      name: name,
      avatar: avatar,
      description: description,
      personality: personality,
      scenario: scenario,
      firstMessage: firstMessage,
      exampleDialogue: exampleDialogue,
      tags: tags,
      preferredModel: preferredModel,
      isSystem: isSystem,
      background: background,
      backgroundOpacity: backgroundOpacity,
    );

    final id = characterBox.put(character);
    return characterBox.get(id)!;
  }

  // 创建工具角色
  Future<void> _createToolCharacters() async {
    // 图像识别专家
    await _createDefaultCharacter(
      characterId: identityHashCode("图像分析师").toString(),
      name: '图像分析师',
      avatar: 'http://img.sccnn.com/bimg/337/39878.jpg',
      description: '专业的图像识别和分析专家，可以分析图片内容，识别物体、场景、文字等元素，并提供详细解释。',
      personality: '观察力敏锐、分析性强、专业、细致。我会仔细分析图像中的各种元素，并提供专业、全面的解读。',
      scenario:
          '我是一位专业的图像分析师，可以帮助你分析和理解各种图像。无论是识别图中的物体、解读场景、提取文字，还是分析图像的构图和风格，我都能提供专业的见解。',
      firstMessage:
          '你好！我是图像分析师，可以帮你分析各种图片。只需发送一张图片，我就能识别其中的内容并提供详细解读。你有什么图像需要分析吗？',
      exampleDialogue:
          '用户: [发送了一张城市街景照片]\n图像分析师: 这张照片展示了一个繁忙的城市街景。我可以看到高楼大厦、行人和车辆。照片右侧有一家咖啡店，招牌上写着"City Brew"。天空呈现蓝色，表明这是在晴天拍摄的。照片的构图采用了透视法，让街道延伸到远处，创造出深度感。你想了解这张照片的哪些具体细节？',
      tags: ['图像', '视觉', '分析'],
      isSystem: true,
    );
  }

  // 创建虚拟角色卡
  Future<void> _createVirtualCharacters() async {
    await _createDefaultCharacter(
      characterId: identityHashCode("齐天大圣孙悟空").toString(),
      name: '齐天大圣孙悟空',
      avatar:
          'https://gd-hbimg.huaban.com/d33962e90585c683ccd513a829cfdb66ce97f951146bf-kSPhPL_fw658webp',
      description:
          '中国古典名著《西游记》中的主角，从石头中诞生的猴王，曾大闹天宫，后被如来佛祖压在五行山下。皈依佛门后，保护唐僧西行取经，历经九九八十一难。',
      personality:
          '桀骜不驯、聪明机智、忠诚、嫉恶如仇、有些自负。我性格直率，不喜欢拐弯抹角，对敌人毫不留情，对朋友却赤诚相待。我有时会耍些小聪明，但内心重情重义。',
      scenario:
          '取经归来后的我，已成为斗战胜佛，但仍保留着猴王的本性。我可能正在云游四海，或是回到花果山探望猴群，偶尔与凡人相遇，分享我的冒险故事和人生感悟。',
      firstMessage:
          '哈哈！俺老孙来也！*耳朵抖动，金箍棒在手中转了个圈* 呔！看你面相不凡，莫非是有什么妖怪缠身？还是想听俺老孙讲讲当年大闹天宫的威风事迹？',
      exampleDialogue:
          '用户: 大圣，我最近遇到了很多困难，感觉自己不够强大，不知道该怎么办。\n孙悟空: *挠挠头* 嘿，别灰心！俺老孙当年可是被压在五行山下五百年哩！*拍拍你的肩膀* 你知道俺老孙为啥厉害吗？不是因为会七十二变，也不是因为火眼金睛。是因为俺有一颗不服输的心！*指着自己的胸口* 再厉害的妖怪，再难的关卡，只要不放弃，总能找到破解之法。你现在的困难，在俺老孙眼里，不过是块绊脚石罢了。挺起胸膛，大胆向前冲！记住，困难越大，说明你越重要，不然妖怪们干嘛非跟你过不去？哈哈哈！',
      tags: ['虚拟', '神话', '中国'],
      isSystem: true,
      backgroundOpacity: 0.25,
    );
  }

  // 导出所有角色卡到用户指定位置
  Future<String> exportCharacters({String? customPath}) async {
    try {
      String filePath;
      if (customPath != null) {
        filePath =
            '$customPath/角色列表_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        final directory = await getAppHomeDirectory();
        filePath =
            '${directory.path}/角色列表_${DateTime.now().millisecondsSinceEpoch}.json';
      }

      final file = File(filePath);

      // 只导出非系统角色
      final userCharacters = characters.where((c) => !c.isSystem).toList();
      final jsonList = userCharacters.map((c) => c.toJson()).toList();

      // 如果角色有预设模型，置为null，因为导出时存在的模型导入时不一定还在
      for (var i = 0; i < jsonList.length; i++) {
        if (jsonList[i]['preferredModel'] != null) {
          jsonList[i]['preferredModel'] = null;
        }
      }

      await file.writeAsString(jsonEncode(jsonList));

      return filePath;
    } catch (e) {
      pl.e('导出角色卡失败: $e');
      rethrow;
    }
  }

  // 从JSON文件导入角色卡
  Future<ImportCharactersResult> importCharacters(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;

      int importedCount = 0;
      int skippedCount = 0;

      for (var json in jsonList) {
        try {
          // 角色的名称、描述不能为空
          if (json['name'] == null || json['name'].toString().trim().isEmpty) {
            ToastUtils.showToast('角色名称不能为空');
            skippedCount++;
            continue;
          }

          if (json['description'] == null ||
              json['description'].toString().trim().isEmpty) {
            ToastUtils.showToast('角色描述不能为空');
            skippedCount++;
            continue;
          }

          // 如果没有头像，默认空字符避免报错
          if (json['avatar'] == null) {
            json['avatar'] = '';
          }

          // 如果角色、描述不为空，但characterId为空，则生成一个characterId
          if (json['characterId'] == null ||
              json['characterId'].toString().trim().isEmpty) {
            json['characterId'] = identityHashCode(json['name']).toString();
          }

          // 如果文件有id，则将其string类型的id转为number类型
          if (json['id'] != null) {
            json['id'] = identityHashCode(json['id']);
          }

          // 如果文件有预设模型，置为null，因为导出时的模型导入时不一定还在
          if (json['preferredModel'] != null) {
            json['preferredModel'] = null;
          }

          final character = CharacterCard.fromJson(json);

          // 检查角色是否已存在
          final existingQuery =
              characterBox
                  .query(
                    CharacterCard_.characterId.equals(character.characterId),
                  )
                  .build();
          final existingCharacter = existingQuery.findFirst();
          existingQuery.close();

          if (existingCharacter != null) {
            // 角色已存在，跳过
            skippedCount++;
            continue;
          }

          // 标记为非系统角色
          character.isSystem = false;
          characterBox.put(character);
          importedCount++;
        } catch (e) {
          // 继续导入其他角色
          pl.e('导入角色失败: $e');
          skippedCount++;
        }
      }

      return ImportCharactersResult(
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ImportCharactersResult {
  final int importedCount;
  final int skippedCount;

  ImportCharactersResult({
    required this.importedCount,
    required this.skippedCount,
  });
}
