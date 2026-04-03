import 'package:flutter/material.dart';

import 'data/diary_store.dart';
import 'pages/detail_page.dart';
import 'pages/editor_page.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key, this.store});

  /// Tuỳ chọn (test). Mặc định: [DiaryStore.seeded] — dữ liệu giả Tuần 2.
  final DiaryStore? store;

  @override
  Widget build(BuildContext context) {
    return DiaryStoreScope(
      store: store ?? DiaryStore.seeded(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nhật ký',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case HomePage.routeName:
              return MaterialPageRoute(
                builder: (_) => const HomePage(),
                settings: settings,
              );
            case SearchPage.routeName:
              return MaterialPageRoute(
                builder: (_) => const SearchPage(),
                settings: settings,
              );
            case EditorPage.routeName:
              final args = settings.arguments;
              final entryId = args is String ? args : null;
              return MaterialPageRoute(
                builder: (_) => EditorPage(entryId: entryId),
                settings: settings,
              );
            case DetailPage.routeName:
              final args = settings.arguments;
              final entryId = args is String ? args : null;
              return MaterialPageRoute(
                builder: (_) => DetailPage(entryId: entryId),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const HomePage(),
                settings: const RouteSettings(name: HomePage.routeName),
              );
          }
        },
        initialRoute: HomePage.routeName,
      ),
    );
  }
}
