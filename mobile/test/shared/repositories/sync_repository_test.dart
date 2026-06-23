import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/core/monitoring/monitoring_service.dart';
import 'package:mobile/src/shared/data/local/app_database.dart';
import 'package:mobile/src/shared/repositories/sync_repository.dart';

class FakeMonitoringService implements MonitoringService {
  final List<String> loggedEvents = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    loggedEvents.add(name);
  }

  @override
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

class FakeDio implements Dio {
  late Future<Response<T>> Function<T>(String path, {Object? data}) postHandler;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return postHandler<T>(path, data: data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase database;
  late FakeDio fakeDio;
  late FakeMonitoringService fakeMonitoring;
  late SyncRepository syncRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fakeDio = FakeDio();
    fakeMonitoring = FakeMonitoringService();
    syncRepository = SyncRepository(fakeDio, database, fakeMonitoring);
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncRepository tests', () {
    test('successful sync (SYNCED) deletes attempt from database', () async {
      // 1. Insert pending attempt
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_1',
          deviceId: 'device_123',
          courseId: 'en_for_vi',
          sourceLanguage: 'vi',
          targetLanguage: 'en',
          lessonId: 'lesson_1',
          lessonVersionId: 'v1',
          questionId: 'q_1',
          questionVersionId: 'qv1',
          selectedAnswer: 'Xin chào',
          responseTimeMs: 1500,
          usedHint: false,
          isCorrectLocal: true,
          answeredAt: DateTime.now(),
        ),
      );

      // 2. Setup mock HTTP response
      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_1',
                'status': 'SYNCED',
                'errorCode': null,
                'message': null,
              }
            ]
          } as T,
          statusCode: 200,
        );
      };

      // 3. Sync
      await syncRepository.syncPendingAttempts();

      // 4. Verify DB is empty
      final list = await database.select(database.pendingAttempts).get();
      expect(list.isEmpty, isTrue);
      expect(fakeMonitoring.loggedEvents.contains('sync_completed'), isTrue);
    });

    test('permanent failure (FAILED) marks attempt status as FAILED_PERMANENT', () async {
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_fail',
          deviceId: 'device_123',
          courseId: 'en_for_vi',
          sourceLanguage: 'vi',
          targetLanguage: 'en',
          lessonId: 'lesson_1',
          lessonVersionId: 'v1',
          questionId: 'q_1',
          questionVersionId: 'qv1',
          selectedAnswer: 'Xin chào',
          responseTimeMs: 1500,
          usedHint: false,
          isCorrectLocal: true,
          answeredAt: DateTime.now(),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_fail',
                'status': 'FAILED',
                'errorCode': 'STALE_CONTENT',
                'message': 'Version mismatch',
              }
            ]
          } as T,
          statusCode: 200,
        );
      };

      await syncRepository.syncPendingAttempts();

      final list = await database.select(database.pendingAttempts).get();
      expect(list.length, 1);
      expect(list.first.status, 'FAILED_PERMANENT');
      expect(list.first.lastError, 'STALE_CONTENT: Version mismatch');
    });

    test('network exception marks attempt status as FAILED_RETRYABLE', () async {
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_network',
          deviceId: 'device_123',
          courseId: 'en_for_vi',
          sourceLanguage: 'vi',
          targetLanguage: 'en',
          lessonId: 'lesson_1',
          lessonVersionId: 'v1',
          questionId: 'q_1',
          questionVersionId: 'qv1',
          selectedAnswer: 'Xin chào',
          responseTimeMs: 1500,
          usedHint: false,
          isCorrectLocal: true,
          answeredAt: DateTime.now(),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionTimeout,
          message: 'Timeout error',
        );
      };

      await syncRepository.syncPendingAttempts();

      final list = await database.select(database.pendingAttempts).get();
      expect(list.length, 1);
      expect(list.first.status, 'FAILED_RETRYABLE');
      expect(list.first.retryCount, 1);
      expect(list.first.lastError, 'Timeout error');
    });
  });
}
