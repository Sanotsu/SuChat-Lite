import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/haokan/haokan_models.dart';

/// 好看漫画本地存储服务
class HaokanStorageService {
  static const String _boxName = 'haokan_storage';
  static const String _favoritesKey = 'favorites';
  static const String _readingProgressKey = 'reading_progress';

  late GetStorage _box;

  static HaokanStorageService? _instance;

  static HaokanStorageService get instance {
    _instance ??= HaokanStorageService._();
    return _instance!;
  }

  HaokanStorageService._();

  /// 初始化存储
  Future<void> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
  }

  /// 收藏相关方法

  /// 获取所有收藏的漫画
  List<HaokanFavoriteComic> getFavoriteComics() {
    final List<dynamic> data = _box.read(_favoritesKey) ?? [];
    return data.map((json) => HaokanFavoriteComic.fromJson(json)).toList();
  }

  /// 添加收藏
  Future<void> addFavorite(HaokanComic comic) async {
    final favorites = getFavoriteComics();

    // 检查是否已经收藏
    if (favorites.any((fav) => fav.comicId == comic.id)) {
      return;
    }

    final favorite = HaokanFavoriteComic(
      comicId: comic.id ?? 0,
      title: comic.title ?? '',
      author: comic.author ?? '',
      pic: comic.pic ?? '',
      lastChapter: comic.lastchapter ?? '',
      favoriteTime: DateTime.now(),
    );

    favorites.add(favorite);
    await _box.write(_favoritesKey, favorites.map((f) => f.toJson()).toList());
  }

  /// 移除收藏
  Future<void> removeFavorite(int comicId) async {
    final favorites = getFavoriteComics();
    favorites.removeWhere((fav) => fav.comicId == comicId);
    await _box.write(_favoritesKey, favorites.map((f) => f.toJson()).toList());
  }

  /// 检查是否已收藏
  bool isFavorite(int comicId) {
    final favorites = getFavoriteComics();
    return favorites.any((fav) => fav.comicId == comicId);
  }

  /// 阅读进度相关方法

  /// 获取漫画的阅读进度
  HaokanReadingProgress? getReadingProgress(int comicId) {
    final Map<String, dynamic> allProgress =
        _box.read(_readingProgressKey) ?? {};
    final progressData = allProgress[comicId.toString()];

    if (progressData != null) {
      return HaokanReadingProgress.fromJson(progressData);
    }
    return null;
  }

  /// 更新阅读进度
  Future<void> updateReadingProgress({
    required int comicId,
    required int chapterId,
    required String chapterName,
    required int imageIndex,
    required int totalImages,
  }) async {
    final Map<String, dynamic> allProgress =
        _box.read(_readingProgressKey) ?? {};

    final progress = HaokanReadingProgress(
      comicId: comicId,
      chapterId: chapterId,
      chapterName: chapterName,
      imageIndex: imageIndex,
      totalImages: totalImages,
      lastReadTime: DateTime.now(),
    );

    allProgress[comicId.toString()] = progress.toJson();
    await _box.write(_readingProgressKey, allProgress);
  }

  /// 获取所有有阅读进度的漫画ID
  List<int> getComicsWithProgress() {
    final Map<String, dynamic> allProgress =
        _box.read(_readingProgressKey) ?? {};
    return allProgress.keys.map((key) => int.parse(key)).toList();
  }

  /// 清除指定漫画的阅读进度
  Future<void> clearReadingProgress(int comicId) async {
    final Map<String, dynamic> allProgress =
        _box.read(_readingProgressKey) ?? {};
    allProgress.remove(comicId.toString());
    await _box.write(_readingProgressKey, allProgress);
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    await _box.erase();
  }
}

/// 收藏的漫画数据模型
class HaokanFavoriteComic {
  final int comicId;
  final String title;
  final String author;
  final String pic;
  final String lastChapter;
  final DateTime favoriteTime;

  HaokanFavoriteComic({
    required this.comicId,
    required this.title,
    required this.author,
    required this.pic,
    required this.lastChapter,
    required this.favoriteTime,
  });

  // 从字符串转
  factory HaokanFavoriteComic.fromRawJson(String str) =>
      HaokanFavoriteComic.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanFavoriteComic.fromJson(Map<String, dynamic> json) {
    return HaokanFavoriteComic(
      comicId: json['comicId'] ?? 0,
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      pic: json['pic'] ?? '',
      lastChapter: json['lastChapter'] ?? '',
      favoriteTime: DateTime.parse(
        json['favoriteTime'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comicId': comicId,
      'title': title,
      'author': author,
      'pic': pic,
      'lastChapter': lastChapter,
      'favoriteTime': favoriteTime.toIso8601String(),
    };
  }
}

/// 阅读进度数据模型
class HaokanReadingProgress {
  final int comicId;
  final int chapterId;
  final String chapterName;
  final int imageIndex;
  final int totalImages;
  final DateTime lastReadTime;

  HaokanReadingProgress({
    required this.comicId,
    required this.chapterId,
    required this.chapterName,
    required this.imageIndex,
    required this.totalImages,
    required this.lastReadTime,
  });

  // 从字符串转
  factory HaokanReadingProgress.fromRawJson(String str) =>
      HaokanReadingProgress.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanReadingProgress.fromJson(Map<String, dynamic> json) {
    return HaokanReadingProgress(
      comicId: json['comicId'] ?? 0,
      chapterId: json['chapterId'] ?? 0,
      chapterName: json['chapterName'] ?? '',
      imageIndex: json['imageIndex'] ?? 0,
      totalImages: json['totalImages'] ?? 0,
      lastReadTime: DateTime.parse(
        json['lastReadTime'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comicId': comicId,
      'chapterId': chapterId,
      'chapterName': chapterName,
      'imageIndex': imageIndex,
      'totalImages': totalImages,
      'lastReadTime': lastReadTime.toIso8601String(),
    };
  }

  /// 计算阅读进度百分比
  double get progressPercentage {
    if (totalImages <= 0) return 0.0;
    return (imageIndex / totalImages).clamp(0.0, 1.0);
  }

  /// 获取进度描述
  String get progressDescription {
    return '${imageIndex + 1}/$totalImages';
  }
}
