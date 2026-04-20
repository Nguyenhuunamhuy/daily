import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/diary_store.dart';

class _PhotoItem {
  _PhotoItem.network({required this.id, required this.url}) : localPath = null;
  _PhotoItem.local({required this.localPath}) : id = null, url = null;

  final String? id;
  final String? url;
  final String? localPath;
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.entryId});

  static const routeName = '/editor';

  final String? entryId;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime _entryDate = DateTime.now();
  final List<_PhotoItem> _photos = [];
  Set<String> _initialRemoteIds = {};

  bool _loadDone = false;
  bool _loadingEntry = false;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfEdit());
  }

  Future<void> _loadIfEdit() async {
    final id = widget.entryId;
    if (id == null) {
      setState(() => _loadDone = true);
      return;
    }
    setState(() {
      _loadingEntry = true;
      _loadError = null;
    });
    try {
      final store = DiaryStoreScope.of(context);
      final entry = await store.fetchEntry(id);
      if (!mounted) return;
      if (entry == null) {
        setState(() {
          _loadingEntry = false;
          _loadDone = true;
          _loadError = 'Không tải được bài nhật ký.';
        });
        return;
      }
      _titleCtrl.text = entry.title;
      _contentCtrl.text = entry.content;
      _entryDate = entry.entryDate;
      _photos
        ..clear()
        ..addAll(
          entry.photos.map((p) => _PhotoItem.network(id: p.id, url: p.url)),
        );
      _initialRemoteIds = entry.photos.where((p) => p.id.isNotEmpty).map((p) => p.id).toSet();
      setState(() {
        _loadingEntry = false;
        _loadDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEntry = false;
        _loadDone = true;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    List<XFile> list;
    try {
      list = await picker.pickMultiImage(imageQuality: 85);
    } on MissingPluginException catch (_) {
      // Một số bản build chỉ thiếu pickMultiImage; thử đơn ảnh. Nếu cả hai đều MissingPlugin → plugin chưa gắn (cần flutter run lại, không Hot Reload).
      try {
        final one = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        list = one != null ? [one] : [];
      } on MissingPluginException catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể mở thư viện ảnh (plugin chưa được gắn vào bản chạy). '
              'Hãy dừng app hoàn toàn, chạy: flutter clean && flutter run — không chỉ Hot Reload.',
            ),
          ),
        );
        return;
      }
    }
    if (list.isEmpty) return;
    setState(() {
      for (final x in list) {
        _photos.add(_PhotoItem.local(localPath: x.path));
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final store = DiaryStoreScope.of(context);

    final locals = _photos.where((p) => p.localPath != null).map((p) => p.localPath!).toList();
    final currentRemoteIds = _photos
        .where((p) => p.id != null && p.id!.isNotEmpty)
        .map((p) => p.id!)
        .toSet();
    final removedIds = _initialRemoteIds.difference(currentRemoteIds).toList();

    setState(() => _saving = true);
    try {
      if (widget.entryId == null) {
        final newId = await store.createEntry(
          title: title,
          content: content,
          entryDate: _entryDate,
          localPhotoPaths: locals,
        );
        if (!mounted) return;
        if (newId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(store.error ?? 'Lưu thất bại')),
          );
          return;
        }
        Navigator.of(context).pop();
        return;
      }

      final ok = await store.updateEntry(
        id: widget.entryId!,
        title: title,
        content: content,
        entryDate: _entryDate,
        newLocalPaths: locals,
        removedPhotoIds: removedIds,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(store.error ?? 'Lưu thất bại')),
        );
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entryId != null;

    if (!_loadDone) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Sửa nhật ký' : 'Tạo nhật ký')),
        body: Center(
          child: _loadingEntry ? const CircularProgressIndicator() : Text(_loadError ?? ''),
        ),
      );
    }

    if (_loadError != null && isEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sửa nhật ký')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_loadError!))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa nhật ký' : 'Tạo nhật ký'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentCtrl,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập nội dung';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày nhật ký'),
              subtitle: Text('${_entryDate.day}/${_entryDate.month}/${_entryDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _entryDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null && mounted) {
                  setState(() => _entryDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Ảnh',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _saving ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Thêm ảnh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photos.isEmpty)
              Text(
                'Chưa có ảnh. Chọn từ thư viện để đăng kèm bài.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              )
            else
              _EditablePhotoGrid(
                items: _photos,
                onRemove: (i) => setState(() => _photos.removeAt(i)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditablePhotoGrid extends StatelessWidget {
  const _EditablePhotoGrid({required this.items, required this.onRemove});

  final List<_PhotoItem> items;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.localPath != null
                    ? Image.file(
                        File(item.localPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image_outlined)),
                      )
                    : Image.network(
                        item.url!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => onRemove(index),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
