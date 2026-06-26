import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    final String url;
    if (fromEnv.isNotEmpty) {
      url = fromEnv;
    } else if (!kIsWeb && Platform.isAndroid) {
      url = 'http://10.0.2.2:8080';
    } else {
      url = 'http://localhost:8080';
    }

    // Guard chặn cấu hình sai trên bản Release (Fail-Fast)
    if (kReleaseMode) {
      final uri = Uri.parse(url);
      final isLocalHost = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2' ||
          uri.host.startsWith('192.168.') ||
          uri.host.startsWith('10.');

      if (uri.scheme != 'https' || isLocalHost) {
        throw StateError(
          'Release build must use a valid HTTPS production API_BASE_URL',
        );
      }
    }

    return url;
  }
}
