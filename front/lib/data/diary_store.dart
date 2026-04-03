import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/diary_entry.dart';

/// Tuần 2: dữ liệu giả trong bộ nhớ (không gọi API).
class DiaryStore extends ChangeNotifier {
  DiaryStore({List<DiaryEntry>? initialEntries})
      : _entries = List.unmodifiable(initialEntries ?? const []);

  factory DiaryStore.seeded() {
    final now = DateTime.now();
    return DiaryStore(
      initialEntries: [
        DiaryEntry(
          id: '1',
          title: 'Ngày đầu tiên',
          content: 'Hôm nay mình bắt đầu viết nhật ký. Đây là bài mẫu.',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
          photoUrls: const ['https://picsum.photos/id/1060/800/600'],
        ),
        DiaryEntry(
          id: '2',
          title: 'Đi dạo buổi tối',
          content: 'Trời mát, mình đi dạo quanh nhà và chụp vài tấm ảnh.',
          createdAt: now.subtract(const Duration(days: 1, hours: 3)),
          updatedAt: now.subtract(const Duration(days: 1, hours: 3)),
          photoUrls: const [
            'https://picsum.photos/id/1011/800/600',
            'https://picsum.photos/id/1015/800/600',
          ],
        ),
        DiaryEntry(
          id: '3',
          title: '',
          content: 'Một bài không có tiêu đề để test UI.',
          createdAt: now.subtract(const Duration(hours: 7)),
          updatedAt: now.subtract(const Duration(hours: 7)),
          photoUrls: const [],
        ),
      ],
    );
  }

  List<DiaryEntry> _entries;
  int _idCounter = 100;
  final _rng = Random();

  List<DiaryEntry> get entries =>
      _entries.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  DiaryEntry? getById(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<DiaryEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q);
    }).toList();
  }

  String create({
    required String title,
    required String content,
    required List<String> photoUrls,
  }) {
    final now = DateTime.now();
    final id = (++_idCounter).toString();
    final entry = DiaryEntry(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      photoUrls: List.unmodifiable(photoUrls),
    );
    _entries = List.unmodifiable([entry, ..._entries]);
    notifyListeners();
    return id;
  }

  void update({
    required String id,
    required String title,
    required String content,
    required List<String> photoUrls,
  }) {
    final now = DateTime.now();
    _entries = List.unmodifiable(
      _entries.map((e) {
        if (e.id != id) return e;
        return e.copyWith(
          title: title,
          content: content,
          updatedAt: now,
          photoUrls: List.unmodifiable(photoUrls),
        );
      }).toList(),
    );
    notifyListeners();
  }

  void delete(String id) {
    _entries = List.unmodifiable(_entries.where((e) => e.id != id).toList());
    notifyListeners();
  }

  /// Ảnh giả (URL) để mô phỏng đăng ảnh — Tuần 5 sẽ thay bằng upload thật.
  String randomPhotoUrl() {
    final id = 1000 + _rng.nextInt(80);
    return 'https://picsum.photos/id/$id/800/600';
  }
}

class DiaryStoreScope extends InheritedNotifier<DiaryStore> {
  const DiaryStoreScope({
    super.key,
    required DiaryStore store,
    required super.child,
  }) : super(notifier: store);

  static DiaryStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiaryStoreScope>();
    assert(scope != null, 'DiaryStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
