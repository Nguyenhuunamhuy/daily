import 'package:flutter/material.dart';

import '../data/diary_store.dart';

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
  final List<String> _photoUrls = [];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final store = DiaryStoreScope.of(context);
    final id = widget.entryId;
    if (id != null) {
      final entry = store.getById(id);
      if (entry != null) {
        _titleCtrl.text = entry.title;
        _contentCtrl.text = entry.content;
        _photoUrls
          ..clear()
          ..addAll(entry.photoUrls);
      }
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DiaryStoreScope.of(context);
    final isEdit = widget.entryId != null;

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
            Row(
              children: [
                Text(
                  'Ảnh (giả lập)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _photoUrls.add(store.randomPhotoUrl())),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Thêm ảnh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photoUrls.isEmpty)
              Text(
                'Chưa có ảnh. Tuần 2 dùng ảnh mẫu từ internet để demo UI.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              )
            else
              _EditablePhotoGrid(
                urls: _photoUrls,
                onRemove: (i) => setState(() => _photoUrls.removeAt(i)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;

                final title = _titleCtrl.text.trim();
                final content = _contentCtrl.text.trim();
                final photos = List<String>.from(_photoUrls);

                if (isEdit) {
                  store.update(
                    id: widget.entryId!,
                    title: title,
                    content: content,
                    photoUrls: photos,
                  );
                  Navigator.of(context).pop();
                } else {
                  store.create(title: title, content: content, photoUrls: photos);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditablePhotoGrid extends StatelessWidget {
  const _EditablePhotoGrid({required this.urls, required this.onRemove});

  final List<String> urls;
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
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final url = urls[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
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
