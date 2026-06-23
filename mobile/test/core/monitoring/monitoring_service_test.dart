import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/core/monitoring/firebase_monitoring_service.dart';
import 'package:mobile/src/shared/repositories/content_repository.dart';

void main() {
  group('FirebaseMonitoringService error filtering tests', () {
    late FirebaseMonitoringService service;

    setUp(() {
      service = FirebaseMonitoringService();
    });

    Future<List<String>> capturePrintsAsync(Future<void> Function() fn) async {
      final prints = <String>[];
      final spec = ZoneSpecification(
        print: (self, parent, zone, line) {
          prints.add(line);
        },
      );
      await Zone.current.fork(specification: spec).run(fn);
      return prints;
    }

    test('OfflineModeException should be filtered', () async {
      final error = OfflineModeException(
        message: 'Offline test',
        isCorrectLocal: true,
        correctAnswer: '',
        explanation: '',
      );
      final logs = await capturePrintsAsync(() => service.logError(error, null));

      expect(logs.any((log) => log.contains('Ignored expected error')), isTrue);
      expect(logs.any((log) => log.contains('[Mock-Crashlytics]')), isFalse);
    });

    test('SocketException should be filtered', () async {
      const error = SocketException('Network is down');
      final logs = await capturePrintsAsync(() => service.logError(error, null));

      expect(logs.any((log) => log.contains('Ignored expected error')), isTrue);
      expect(logs.any((log) => log.contains('[Mock-Crashlytics]')), isFalse);
    });

    test('DioException with connectionTimeout should be filtered', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api'),
        type: DioExceptionType.connectionTimeout,
        message: 'Timeout',
      );
      final logs = await capturePrintsAsync(() => service.logError(error, null));

      expect(logs.any((log) => log.contains('Ignored expected error')), isTrue);
    });

    test('DioException with HTTP 400 validation error should be filtered', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api'),
          statusCode: 400,
        ),
      );
      final logs = await capturePrintsAsync(() => service.logError(error, null));

      expect(logs.any((log) => log.contains('Ignored expected error')), isTrue);
    });

    test('Standard exceptions should NOT be filtered (logged to Crashlytics/Mock)', () async {
      final error = Exception('Critical server error');
      final logs = await capturePrintsAsync(() => service.logError(error, null));

      expect(logs.any((log) => log.contains('Ignored expected error')), isFalse);
      expect(logs.any((log) => log.contains('[Mock-Crashlytics]')), isTrue);
    });
  });
}
