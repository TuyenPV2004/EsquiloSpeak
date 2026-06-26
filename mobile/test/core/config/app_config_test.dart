import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('apiBaseUrl returns default fallback or defined environment variable', () {
      final url = AppConfig.apiBaseUrl;
      expect(url, isNotEmpty);
      expect(url.startsWith('http://') || url.startsWith('https://'), true);
    });
  });
}
