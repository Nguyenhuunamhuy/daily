import 'dart:async';

import 'package:flutter/material.dart';

import '../data/diary_store.dart';
import '../models/diary_entry.dart';
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
  Timer? _debounce;
  List<DiaryEntry>? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    final qTrim = q.trim();
    if (qTrim.isEmpty) {
      setState(() {
        _results = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      final store = DiaryStoreScope.of(context);
      final list = await store.fetchList(query: qTrim);
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final results = _results;

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
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                            _results = null;
                            _error = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  if (_controller.text.trim().isNotEmpty) {
                    _loading = true;
                  } else {
                    _loading = false;
                    _results = null;
                    _error = null;
                  }
                });
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  _runSearch(_controller.text);
                });
              },
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nhập từ khoá để tìm.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : results != null && results.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Không tìm thấy kết quả.',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              )
                            : results == null
                                ? const SizedBox.shrink()
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
