import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/shared/network/api_error_parser.dart';

void main() {
  group('ApiErrorParser Tests', () {
    test('extracts error code from standard OpenAPI envelope', () {
      final json = {
        'error': {'code': 'LESSON_ALREADY_COMPLETED', 'message': 'Already done'},
        'meta': {'requestId': 'req_123', 'apiVersion': 'v1'}
      };
      expect(ApiErrorParser.extractErrorCode(json), equals('LESSON_ALREADY_COMPLETED'));
      expect(ApiErrorParser.extractErrorMessage(json), equals('Already done'));
    });

    test('extracts error code from legacy root level fallback', () {
      final json = {'code': 'STALE_CONTENT', 'message': 'Stale version'};
      expect(ApiErrorParser.extractErrorCode(json), equals('STALE_CONTENT'));
      expect(ApiErrorParser.extractErrorMessage(json), equals('Stale version'));
    });

    test('returns null for non-map or empty response data', () {
      expect(ApiErrorParser.extractErrorCode(null), isNull);
      expect(ApiErrorParser.extractErrorCode('string_error'), isNull);
      expect(ApiErrorParser.extractErrorCode({}), isNull);
    });
  });
}
