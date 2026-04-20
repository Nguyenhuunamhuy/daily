import 'package:flutter/widgets.dart';

import '../config/api_config.dart';
import '../models/diary_entry.dart';
import 'diary_api.dart';

class DiaryStore extends ChangeNotifier {
  DiaryStore({DiaryApi? api}) : _api = api ?? DiaryApi(baseUrl: ApiConfig.baseUrl);

  final DiaryApi _api;

  List<DiaryEntry> _entries = [];
  bool _loading = false;
  String? _error;

  List<DiaryEntry> get entries =>
      List<DiaryEntry>.from(_entries)..sort((a, b) => b.entryDate.compareTo(a.entryDate));

  bool get loading => _loading;
  String? get error => _error;

  DiaryApi get api => _api;

  Future<List<DiaryEntry>> fetchList({String? query}) => _api.listEntries(query: query);

  Future<void> refreshList({String? query}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _api.listEntries(query: query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<DiaryEntry?> fetchEntry(String id) async {
    try {
      return await _api.getEntry(id);
    } catch (_) {
      return null;
    }
  }

  Future<String?> createEntry({
    required String title,
    required String content,
    required DateTime entryDate,
    required List<String> localPhotoPaths,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final created = await _api.createEntry(title: title, content: content, entryDate: entryDate);
      if (localPhotoPaths.isNotEmpty) {
        await _api.uploadPhotos(created.id, localPhotoPaths);
      }
      await refreshList();
      return created.id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateEntry({
    required String id,
    required String title,
    required String content,
    required DateTime entryDate,
    required List<String> newLocalPaths,
    required List<String> removedPhotoIds,
  }) async {
    _error = null;
    notifyListeners();
    try {
      for (final pid in removedPhotoIds) {
        if (pid.isNotEmpty) await _api.deletePhoto(pid);
      }
      await _api.updateEntry(id: id, title: title, content: content, entryDate: entryDate);
      if (newLocalPaths.isNotEmpty) {
        await _api.uploadPhotos(id, newLocalPaths);
      }
      await refreshList();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    _error = null;
    notifyListeners();
    try {
      await _api.deleteEntry(id);
      await refreshList();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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
