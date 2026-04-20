import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../models/diary_entry.dart';
import '../models/diary_photo.dart';

class DiaryApiException implements Exception {
  DiaryApiException(this.statusCode, this.message, {this.body});

  final int statusCode;
  final String message;
  final String? body;

  @override
  String toString() => 'DiaryApiException($statusCode): $message';
}

class DiaryApi {
  DiaryApi({required String baseUrl}) : _base = baseUrl.replaceAll(RegExp(r'/$'), '');

  final String _base;

  Uri _u(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_base$p').replace(queryParameters: query);
  }

  String resolveUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('/')) return '$_base$pathOrUrl';
    return '$_base/$pathOrUrl';
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw DiaryApiException(500, 'Phản hồi JSON không hợp lệ');
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode < 400) return;
    String msg = 'Lỗi mạng (${r.statusCode})';
    try {
      final o = _decodeObject(r.body);
      final err = o['error'];
      if (err is Map && err['message'] is String) {
        msg = err['message'] as String;
      }
    } catch (_) {}
    throw DiaryApiException(r.statusCode, msg, body: r.body);
  }

  Future<List<DiaryEntry>> listEntries({int page = 1, int limit = 50, String? query}) async {
    final q = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (query != null && query.trim().isNotEmpty) {
      q['query'] = query.trim();
    }
    final r = await http.get(_u('/api/entries', q));
    _throwIfError(r);
    final o = _decodeObject(r.body);
    final data = o['data'];
    if (data is! Map) throw DiaryApiException(500, 'Định dạng data không hợp lệ');
    final items = data['items'];
    if (items is! List) throw DiaryApiException(500, 'items không hợp lệ');
    return items.map((e) => _entryFromListJson(e as Map<String, dynamic>)).toList();
  }

  DiaryEntry _entryFromListJson(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final title = (j['title'] as String?) ?? '';
    final preview = (j['contentPreview'] as String?) ?? '';
    final entryDate = _ms(j['entryDate']);
    final createdAt = _ms(j['createdAt']);
    final updatedAt = _ms(j['updatedAt']);
    final cover = j['coverPhotoUrl'] as String?;
    final photos = <DiaryPhotoEntry>[
      if (cover != null && cover.isNotEmpty)
        DiaryPhotoEntry(id: '', url: resolveUrl(cover)),
    ];
    return DiaryEntry(
      id: id,
      title: title,
      content: preview,
      entryDate: entryDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photos: photos,
    );
  }

  DateTime _ms(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return DateTime.now();
  }

  Future<DiaryEntry> getEntry(String id) async {
    final r = await http.get(_u('/api/entries/$id'));
    _throwIfError(r);
    final o = _decodeObject(r.body);
    final data = o['data'];
    if (data is! Map<String, dynamic>) {
      throw DiaryApiException(500, 'data không hợp lệ');
    }
    return _entryFromDetailJson(data);
  }

  DiaryEntry _entryFromDetailJson(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final title = (j['title'] as String?) ?? '';
    final content = (j['content'] as String?) ?? '';
    final entryDate = _ms(j['entryDate']);
    final createdAt = _ms(j['createdAt']);
    final updatedAt = _ms(j['updatedAt']);
    final rawPhotos = j['photos'];
    final photos = <DiaryPhotoEntry>[];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p is! Map<String, dynamic>) continue;
        final pid = p['id'] as String? ?? '';
        final url = p['url'] as String? ?? '';
        if (url.isEmpty) continue;
        photos.add(DiaryPhotoEntry(id: pid, url: resolveUrl(url)));
      }
    }
    return DiaryEntry(
      id: id,
      title: title,
      content: content,
      entryDate: entryDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photos: photos,
    );
  }

  Future<DiaryEntry> createEntry({required String title, required String content, required DateTime entryDate}) async {
    final r = await http.post(
      _u('/api/entries'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content, 'entryDate': entryDate.millisecondsSinceEpoch}),
    );
    _throwIfError(r);
    final o = _decodeObject(r.body);
    final data = o['data'];
    if (data is! Map<String, dynamic>) throw DiaryApiException(500, 'data không hợp lệ');
    return _entryFromDetailJson(data);
  }

  Future<DiaryEntry> updateEntry({
    required String id,
    required String title,
    required String content,
    required DateTime entryDate,
  }) async {
    final r = await http.put(
      _u('/api/entries/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content, 'entryDate': entryDate.millisecondsSinceEpoch}),
    );
    _throwIfError(r);
    final o = _decodeObject(r.body);
    final data = o['data'];
    if (data is! Map<String, dynamic>) throw DiaryApiException(500, 'data không hợp lệ');
    return _entryFromDetailJson(data);
  }

  Future<void> deleteEntry(String id) async {
    final r = await http.delete(_u('/api/entries/$id'));
    _throwIfError(r);
  }

  Future<void> deletePhoto(String photoId) async {
    final r = await http.delete(_u('/api/photos/$photoId'));
    _throwIfError(r);
  }

  Future<List<DiaryPhotoEntry>> uploadPhotos(String entryId, List<String> filePaths) async {
    if (filePaths.isEmpty) return [];
    final uri = _u('/api/entries/$entryId/photos');
    final req = http.MultipartRequest('POST', uri);
    for (final path in filePaths) {
      final mime = lookupMimeType(path);
      final MediaType? ct = mime != null ? MediaType.parse(mime) : null;
      req.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          path,
          contentType: ct,
        ),
      );
    }
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    _throwIfError(r);
    final o = _decodeObject(r.body);
    final data = o['data'];
    if (data is! Map) throw DiaryApiException(500, 'data không hợp lệ');
    final list = data['photos'];
    if (list is! List) return [];
    final out = <DiaryPhotoEntry>[];
    for (final p in list) {
      if (p is! Map<String, dynamic>) continue;
      final pid = p['id'] as String? ?? '';
      final url = p['url'] as String? ?? '';
      if (url.isEmpty) continue;
      out.add(DiaryPhotoEntry(id: pid, url: resolveUrl(url)));
    }
    return out;
  }
}
