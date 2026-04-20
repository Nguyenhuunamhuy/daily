import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../models/diary_entry.dart';
import 'editor_page.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.entryId});

  static const routeName = '/detail';

  final String? entryId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  DiaryEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = widget.entryId;
    if (id == null) {
      setState(() {
        _entry = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final e = await DiaryStoreScope.of(context).fetchEntry(id);
    if (!mounted) return;
    setState(() {
      _entry = e;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = DiaryStoreScope.of(context);
    final entry = _entry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nhật ký'),
        actions: [
          if (!_loading && entry != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await Navigator.of(context).pushNamed(
                      EditorPage.routeName,
                      arguments: entry.id,
                    );
                    if (!mounted) return;
                    await _load();
                    break;
                  case 'delete':
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xoá bài nhật ký?'),
                        content: const Text('Hành động này không thể hoàn tác.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Huỷ'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Xoá'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final ok2 = await store.deleteEntry(entry.id);
                      if (!context.mounted) return;
                      if (ok2) Navigator.of(context).pop();
                    }
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xoá')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : entry == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Không tìm thấy bài nhật ký.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      entry.title.trim().isEmpty ? '(Không có tiêu đề)' : entry.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(entry.entryDate),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      entry.content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (entry.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Ảnh',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _PhotoGrid(urls: entry.photoUrls),
                    ],
                  ],
                ),
      floatingActionButton: _loading || entry == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  EditorPage.routeName,
                  arguments: entry.id,
                );
                if (!mounted) return;
                await _load();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Sửa'),
            ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.urls});

  final List<String> urls;

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
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        );
      },
    );
  }
}
