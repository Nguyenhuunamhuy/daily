class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.photoUrls,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> photoUrls;

  DiaryEntry copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    List<String>? photoUrls,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}
