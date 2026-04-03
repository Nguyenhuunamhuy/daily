import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../widgets/entry_card.dart';
import 'detail_page.dart';
import 'editor_page.dart';
import 'search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const routeName = '/';

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
      body: entries.isEmpty
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
                      onPressed: () => Navigator.of(context).pushNamed(EditorPage.routeName),
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo mới'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return EntryCard(
                  entry: entry,
                  onTap: () => Navigator.of(context).pushNamed(
                    DetailPage.routeName,
                    arguments: entry.id,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(EditorPage.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
    );
  }
}
