import 'diary_photo.dart';

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    required this.photos,
  });

  final String id;
  final String title;
  final String content;
  final DateTime entryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DiaryPhotoEntry> photos;

  List<String> get photoUrls => photos.map((p) => p.url).toList();

  DiaryEntry copyWith({
    String? title,
    String? content,
    DateTime? entryDate,
    DateTime? updatedAt,
    List<DiaryPhotoEntry>? photos,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photos: photos ?? this.photos,
    );
  }
}
