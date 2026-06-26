import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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

    test('stuck syncing attempt is recovered to PENDING on sync start', () async {
      // Insert a stuck syncing attempt
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_stuck',
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
          status: const Value('SYNCING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_stuck',
                'status': 'SYNCED',
                'errorCode': null,
                'message': null,
              }
            ]
          } as T,
          statusCode: 200,
        );
      };

      await syncRepository.syncPendingAttempts();

      final list = await database.select(database.pendingAttempts).get();
      expect(list.isEmpty, isTrue);
    });

    test('syncPendingLessons successfully POSTs and updates syncStatus to SYNCED', () async {
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_completed_offline',
          courseId: 'en_for_vi',
          title: 'Offline Lesson',
          status: 'completed',
          syncStatus: const Value('PENDING'),
        ),
      );

      final List<String> postedPaths = [];
      fakeDio.postHandler = <T>(path, {data}) async {
        postedPaths.add(path);
        if (path.contains('/complete')) {
          return Response<T>(
            requestOptions: RequestOptions(path: path),
            data: {'success': true} as T,
            statusCode: 200,
          );
        }
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {'success': true, 'results': []} as T,
          statusCode: 200,
        );
      };

      await syncRepository.syncPendingAttempts();

      expect(postedPaths.any((p) => p.contains('/courses/en_for_vi/lessons/lesson_completed_offline/complete')), isTrue);

      final lessons = await database.select(database.cachedLessons).get();
      final updatedLesson = lessons.firstWhere((l) => l.lessonId == 'lesson_completed_offline');
      expect(updatedLesson.syncStatus, 'SYNCED');
    });

    test('syncPendingLessons 422 reverts lesson status to available and syncStatus to SYNCED', () async {
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_422',
          courseId: 'en_for_vi',
          title: 'Offline Lesson',
          status: 'completed',
          syncStatus: const Value('PENDING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 422,
            data: {'code': 'LESSON_INCOMPLETE'},
          ),
        );
      };

      await syncRepository.syncPendingLessons();

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_422')))
          .getSingle();
      expect(lesson.status, 'available');
      expect(lesson.syncStatus, 'SYNCED');
    });

    test('syncPendingLessons transient network error keeps completed and PENDING', () async {
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_transient',
          courseId: 'en_for_vi',
          title: 'Offline Lesson',
          status: 'completed',
          syncStatus: const Value('PENDING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionTimeout,
          message: 'Timeout',
        );
      };

      await syncRepository.syncPendingLessons();

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_transient')))
          .getSingle();
      expect(lesson.status, 'completed');
      expect(lesson.syncStatus, 'PENDING');
    });

    test('syncPendingLessons 409 LESSON_ALREADY_COMPLETED updates syncStatus to SYNCED', () async {
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_409',
          courseId: 'en_for_vi',
          title: 'Offline Lesson',
          status: 'completed',
          syncStatus: const Value('PENDING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 409,
            data: {'code': 'LESSON_ALREADY_COMPLETED'},
          ),
        );
      };

      await syncRepository.syncPendingLessons();

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_409')))
          .getSingle();
      expect(lesson.status, 'completed');
      expect(lesson.syncStatus, 'SYNCED');
    });

    test('syncPendingLessons 401 throws SyncAuthRequiredException and stops processing', () async {
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_auth_err',
          courseId: 'en_for_vi',
          title: 'Offline Lesson',
          status: 'completed',
          syncStatus: const Value('PENDING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
        );
      };

      expect(
        () => syncRepository.syncPendingLessons(),
        throwsA(isA<SyncAuthRequiredException>()),
      );

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_auth_err')))
          .getSingle();
      expect(lesson.status, 'completed'); // untouched
      expect(lesson.syncStatus, 'PENDING'); // untouched
    });

    test('syncPendingAttempts filters out FAILED_RETRYABLE attempts that occurred less than 5 minutes ago', () async {
      final now = DateTime.now();
      
      // Attempt 1: FAILED_RETRYABLE và lastTriedAt cách đây 1 phút (không được đồng bộ)
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_retry_recent',
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
          answeredAt: now.subtract(const Duration(minutes: 10)),
          status: const Value('FAILED_RETRYABLE'),
          lastTriedAt: Value(now.subtract(const Duration(minutes: 1))),
          retryCount: const Value(1),
        ),
      );

      // Attempt 2: FAILED_RETRYABLE và lastTriedAt cách đây 6 phút (thỏa mãn -> được đồng bộ)
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_retry_eligible',
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
          answeredAt: now.subtract(const Duration(minutes: 10)),
          status: const Value('FAILED_RETRYABLE'),
          lastTriedAt: Value(now.subtract(const Duration(minutes: 6))),
          retryCount: const Value(1),
        ),
      );

      final List<String> syncedReqIds = [];
      fakeDio.postHandler = <T>(path, {data}) async {
        final body = data as Map<String, dynamic>;
        final attemptsList = body['attempts'] as List;
        for (final a in attemptsList) {
          syncedReqIds.add(a['clientRequestId'] as String);
        }
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_retry_eligible',
                'status': 'SYNCED',
                'errorCode': null,
                'message': null,
              }
            ]
          } as T,
          statusCode: 200,
        );
      };

      await syncRepository.syncPendingAttempts();

      expect(syncedReqIds.contains('req_retry_recent'), isFalse);
      expect(syncedReqIds.contains('req_retry_eligible'), isTrue);

      // req_retry_eligible đã bị xóa vì sync thành công
      final list = await database.select(database.pendingAttempts).get();
      expect(list.length, 1);
      expect(list.first.clientRequestId, 'req_retry_recent');
    });

    test('syncPendingAttempts handles RETRYABLE_FAILED and increments retryCount', () async {
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_retryable_err',
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
          status: const Value('PENDING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_retryable_err',
                'status': 'RETRYABLE_FAILED',
                'errorCode': 'QUESTION_VERSION_MISSING',
                'message': 'Version missing on server',
              }
            ]
          } as T,
          statusCode: 200,
        );
      };

      await syncRepository.syncPendingAttempts();

      final list = await database.select(database.pendingAttempts).get();
      expect(list.length, 1);
      expect(list.first.status, 'FAILED_RETRYABLE');
      expect(list.first.retryCount, 1);
      expect(list.first.lastError, 'QUESTION_VERSION_MISSING: Version missing on server');
    });

    test('syncPendingAttempts marks as FAILED_PERMANENT when retryCount reaches 5', () async {
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_max_retry',
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
          status: const Value('FAILED_RETRYABLE'),
          lastTriedAt: Value(DateTime.now().subtract(const Duration(minutes: 6))),
          retryCount: const Value(4), // Đã retry 4 lần, lần thứ 5 sẽ fail permanent
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_max_retry',
                'status': 'RETRYABLE_FAILED',
                'errorCode': 'QUESTION_VERSION_MISSING',
                'message': 'Still missing',
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
      expect(list.first.retryCount, 5);
    });

    test('syncPendingAttempts invalidates lesson cache on STALE_CONTENT sync error', () async {
      // 1. Setup cached lesson and question
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_stale',
          courseId: 'en_for_vi',
          title: 'Stale Lesson',
          status: 'available',
        ),
      );

      await database.cacheLessonDetails(
        lessonId: 'lesson_stale',
        questions: [
          CachedQuestionsCompanion.insert(
            questionId: 'q_stale',
            lessonId: 'lesson_stale',
            prompt: 'Stale Question',
            type: 'multiple_choice',
            correctAnswer: 'A',
            explanation: 'Exp',
            questionVersionId: 'v1',
          )
        ],
        options: [],
      );

      // 2. Insert pending attempt
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_stale_sync',
          deviceId: 'device_123',
          courseId: 'en_for_vi',
          sourceLanguage: 'vi',
          targetLanguage: 'en',
          lessonId: 'lesson_stale',
          lessonVersionId: 'v1',
          questionId: 'q_stale',
          questionVersionId: 'v1',
          selectedAnswer: 'A',
          responseTimeMs: 1500,
          usedHint: false,
          isCorrectLocal: true,
          answeredAt: DateTime.now(),
          status: const Value('PENDING'),
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'success': true,
            'results': [
              {
                'clientRequestId': 'req_stale_sync',
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

      // Attempt becomes FAILED_PERMANENT
      final attempts = await database.select(database.pendingAttempts).get();
      expect(attempts.length, 1);
      expect(attempts.first.status, 'FAILED_PERMANENT');

      // Cache is invalidated
      final questions = await database.select(database.cachedQuestions).get();
      expect(questions.isEmpty, isTrue);
    });

    test('syncPendingLessons does not defer complete call if all attempts are FAILED_PERMANENT', () async {
      // 1. Setup cached lesson completed offline
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_test_FP',
          courseId: 'en_for_vi',
          title: 'FP Lesson',
          status: 'completed',
          syncStatus: const Value('PENDING'),
        ),
      );

      // 2. Insert FAILED_PERMANENT pending attempt
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_FP',
          deviceId: 'device_123',
          courseId: 'en_for_vi',
          sourceLanguage: 'vi',
          targetLanguage: 'en',
          lessonId: 'lesson_test_FP',
          lessonVersionId: 'v1',
          questionId: 'q_1',
          questionVersionId: 'v1',
          selectedAnswer: 'A',
          responseTimeMs: 1000,
          usedHint: false,
          isCorrectLocal: true,
          answeredAt: DateTime.now(),
          status: const Value('FAILED_PERMANENT'),
        ),
      );

      bool completeLessonCalled = false;
      fakeDio.postHandler = <T>(path, {data}) async {
        if (path.contains('/complete')) {
          completeLessonCalled = true;
          return Response<T>(
            requestOptions: RequestOptions(path: path),
            data: {'success': true} as T,
            statusCode: 200,
          );
        }
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {} as T,
          statusCode: 200,
        );
      };

      await syncRepository.syncPendingLessons();

      // Defer should be skipped, so complete lesson is called and lesson marked as SYNCED
      expect(completeLessonCalled, isTrue);
      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.lessonId.equals('lesson_test_FP')))
          .getSingle();
      expect(lesson.syncStatus, 'SYNCED');
    });

    test('resetFailedPermanentAttempts and discardFailedPermanentAttempts work correctly', () async {
      // 1. Insert FAILED_PERMANENT pending attempt
      await database.into(database.pendingAttempts).insert(
        PendingAttemptsCompanion.insert(
          clientRequestId: 'req_FP_reset',
          deviceId: 'device_123',
          courseId: 'en_for_vi',
          sourceLanguage: 'vi',
          targetLanguage: 'en',
          lessonId: 'lesson_1',
          lessonVersionId: 'v1',
          questionId: 'q_1',
          questionVersionId: 'v1',
          selectedAnswer: 'A',
          responseTimeMs: 1000,
          usedHint: false,
          isCorrectLocal: true,
          answeredAt: DateTime.now(),
          status: const Value('FAILED_PERMANENT'),
          retryCount: const Value(5),
          lastError: const Value('Stale version'),
          lastTriedAt: Value(DateTime.now()),
        ),
      );

      // Verify watchFailedPermanentCount is 1
      var fpCount = await syncRepository.watchFailedPermanentCount().first;
      expect(fpCount, 1);

      // 2. Reset permanent failures
      await syncRepository.resetFailedPermanentAttempts();

      final attemptAfterReset = await database.select(database.pendingAttempts).getSingle();
      expect(attemptAfterReset.status, 'PENDING');
      expect(attemptAfterReset.retryCount, 0);
      expect(attemptAfterReset.lastError, isNull);
      expect(attemptAfterReset.lastTriedAt, isNull);

      // Verify watchFailedPermanentCount is now 0
      fpCount = await syncRepository.watchFailedPermanentCount().first;
      expect(fpCount, 0);

      // Mark back to FAILED_PERMANENT to test discard
      await (database.update(database.pendingAttempts)..where((t) => t.id.equals(attemptAfterReset.id)))
          .write(const PendingAttemptsCompanion(status: Value('FAILED_PERMANENT')));

      // 3. Discard permanent failures
      await syncRepository.discardFailedPermanentAttempts();

      final attempts = await database.select(database.pendingAttempts).get();
      expect(attempts.isEmpty, isTrue);
    });
  });
}
