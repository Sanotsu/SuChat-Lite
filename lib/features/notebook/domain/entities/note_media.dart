/// 笔记媒体附件实体类
class NoteMedia {
  final int? id;
  final int noteId;
  final String mediaType; // image, audio, video
  final String mediaPath;
  final String? thumbnailPath;
  final DateTime createdAt;

  NoteMedia({
    this.id,
    required this.noteId,
    required this.mediaType,
    required this.mediaPath,
    this.thumbnailPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 从数据库映射创建NoteMedia对象
  factory NoteMedia.fromMap(Map<String, dynamic> map) {
    return NoteMedia(
      id: map['media_id'],
      noteId: map['note_id'],
      mediaType: map['media_type'],
      mediaPath: map['media_path'],
      thumbnailPath: map['thumbnail_path'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'media_id': id,
      'note_id': noteId,
      'media_type': mediaType,
      'media_path': mediaPath,
      'thumbnail_path': thumbnailPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 创建副本
  NoteMedia copyWith({
    int? id,
    int? noteId,
    String? mediaType,
    String? mediaPath,
    String? thumbnailPath,
    DateTime? createdAt,
  }) {
    return NoteMedia(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      mediaType: mediaType ?? this.mediaType,
      mediaPath: mediaPath ?? this.mediaPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 检查媒体类型
  bool get isImage => mediaType == 'image';
  bool get isAudio => mediaType == 'audio';
  bool get isVideo => mediaType == 'video';

  @override
  String toString() {
    return 'NoteMedia{id: $id, noteId: $noteId, mediaType: $mediaType, mediaPath: $mediaPath}';
  }
}
