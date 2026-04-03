import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../widgets/entry_card.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const routeName = '/search';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DiaryStoreScope.of(context);
    final query = _controller.text;
    final results = store.search(query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập từ khoá (tiêu đề/nội dung)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xoá',
                        onPressed: () => setState(() => _controller.clear()),
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy kết quả.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final entry = results[index];
                      return EntryCard(
                        entry: entry,
                        onTap: () => Navigator.of(context).pushNamed(
                          DetailPage.routeName,
                          arguments: entry.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
