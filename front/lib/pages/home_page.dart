import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../widgets/entry_card.dart';
import 'detail_page.dart';
import 'editor_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routeName = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DiaryStoreScope.of(context).refreshList();
    });
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).pushNamed(EditorPage.routeName);
    if (!mounted) return;
    await DiaryStoreScope.of(context).refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final store = DiaryStoreScope.of(context);
    final entries = store.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            onPressed: () => Navigator.of(context).pushNamed(SearchPage.routeName),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: store.loading && entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : store.error != null && entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          'Không tải được dữ liệu.\n${store.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => store.refreshList(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 56,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có bài nhật ký nào',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hãy viết bài nhật ký đầu tiên của bạn.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _openEditor,
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo mới'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => store.refreshList(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return EntryCard(
                            entry: entry,
                            onTap: () async {
                              await Navigator.of(context).pushNamed(
                                DetailPage.routeName,
                                arguments: entry.id,
                              );
                              if (!mounted) return;
                              await store.refreshList();
                            },
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
    );
  }
}
