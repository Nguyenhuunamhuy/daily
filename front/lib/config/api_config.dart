import 'package:flutter/foundation.dart';

/// Base URL của backend.
///
/// - Windows/macOS desktop / iOS simulator: `http://127.0.0.1:3000`
/// - Android (native app, thường là emulator): mặc định `http://10.0.2.2:3000`
/// - Web: `http://127.0.0.1:3000`
/// - Thiết bị thật Android: gán IP máy chạy Node, ví dụ
///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
abstract final class ApiConfig {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }
}
