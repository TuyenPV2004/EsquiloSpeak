import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:mobile/src/core/device/device_id_service.dart';
import 'package:mobile/src/shared/data/local/app_database.dart';
import 'package:mobile/src/shared/repositories/content_repository.dart';

class FakeDeviceIdService implements DeviceIdService {
  final String _mockId;
  int callCount = 0;

  FakeDeviceIdService(this._mockId);

  @override
  Future<String> getOrCreateDeviceId() async {
    callCount++;
    return _mockId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  late FakeDeviceIdService fakeDeviceIdService;
  late ContentRepository contentRepository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    fakeDio = FakeDio();
    fakeDeviceIdService = FakeDeviceIdService('dev_test_123');
    contentRepository = ContentRepository(fakeDio, database, fakeDeviceIdService);

    // Pre-populate cached course
    await database.into(database.cachedCourses).insert(
      CachedCoursesCompanion.insert(
        courseId: 'en_for_vi',
        title: 'English for Vietnamese',
        sourceLanguage: 'vi',
        targetLanguage: 'en',
        level: 'A0-A1',
      ),
    );

    // Pre-populate cached question
    await database.into(database.cachedQuestions).insert(
      CachedQuestionsCompanion.insert(
        questionId: 'q_1',
        lessonId: 'lesson_1',
        prompt: 'Hello',
        type: 'multiple_choice',
        correctAnswer: 'Xin chào',
        explanation: 'Explanation',
        questionVersionId: 'qv1',
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('ContentRepository submitAttempt Tests', () {
    test('online submission uses the real device ID from DeviceIdService', () async {
      Map<String, dynamic>? capturedPayload;

      fakeDio.postHandler = <T>(path, {data}) async {
        capturedPayload = data as Map<String, dynamic>?;
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {
            'isCorrect': true,
            'correctAnswer': 'Xin chào',
            'explanation': 'Explanation',
            'reviewCreated': false,
          } as T,
        );
      };

      final response = await contentRepository.submitAttempt(
        courseId: 'en_for_vi',
        lessonId: 'lesson_1',
        lessonVersionId: 'lesson_server_v2',
        questionId: 'q_1',
        questionVersionId: 'qv1',
        selectedAnswer: 'Xin chào',
        responseTimeMs: 1200,
        usedHint: false,
        clientRequestId: 'req_online_1',
      );

      expect(response.isCorrect, true);
      expect(fakeDeviceIdService.callCount, 1);
      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['deviceId'], 'dev_test_123');
      expect(capturedPayload!['lessonVersionId'], 'lesson_server_v2');
    });

    test('offline DioException stores the correct device ID and lesson version in drift DB', () async {
      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
        );
      };

      try {
        await contentRepository.submitAttempt(
          courseId: 'en_for_vi',
          lessonId: 'lesson_1',
          lessonVersionId: 'lesson_server_v2',
          questionId: 'q_1',
          questionVersionId: 'qv1',
          selectedAnswer: 'Xin chào',
          responseTimeMs: 1200,
          usedHint: false,
          clientRequestId: 'req_offline_dio',
        );
        fail('Should have thrown OfflineModeException');
      } on OfflineModeException catch (e) {
        expect(e.isCorrectLocal, true);
      }

      expect(fakeDeviceIdService.callCount, 1);

      // Verify DB contains the attempt with the correct device ID
      final savedAttempt = await (database.select(database.pendingAttempts)
            ..where((t) => t.clientRequestId.equals('req_offline_dio')))
          .getSingle();

      expect(savedAttempt.deviceId, 'dev_test_123');
      expect(savedAttempt.lessonVersionId, 'lesson_server_v2');
    });

    test('offline SocketException stores the correct device ID and lesson version in drift DB', () async {
      fakeDio.postHandler = <T>(path, {data}) async {
        throw const SocketException('No Internet');
      };

      try {
        await contentRepository.submitAttempt(
          courseId: 'en_for_vi',
          lessonId: 'lesson_1',
          lessonVersionId: 'lesson_server_v2',
          questionId: 'q_1',
          questionVersionId: 'qv1',
          selectedAnswer: 'Tạm biệt',
          responseTimeMs: 1500,
          usedHint: true,
          clientRequestId: 'req_offline_socket',
        );
        fail('Should have thrown OfflineModeException');
      } on OfflineModeException catch (e) {
        expect(e.isCorrectLocal, false);
      }

      expect(fakeDeviceIdService.callCount, 1);

      // Verify DB contains the attempt with the correct device ID
      final savedAttempt = await (database.select(database.pendingAttempts)
            ..where((t) => t.clientRequestId.equals('req_offline_socket')))
          .getSingle();

      expect(savedAttempt.deviceId, 'dev_test_123');
      expect(savedAttempt.lessonVersionId, 'lesson_server_v2');
    });

    test('online submission returning 400 STALE_CONTENT invalidates cache and throws StaleContentException', () async {
      // Setup cached lesson so cache invalidation validation passes
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_1',
          courseId: 'en_for_vi',
          title: 'Lesson 1',
          status: 'available',
        ),
      );

      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 400,
            data: {
              'error': {
                'code': 'STALE_CONTENT',
                'message': 'Stale version',
              }
            },
          ),
        );
      };

      await expectLater(
        () => contentRepository.submitAttempt(
          courseId: 'en_for_vi',
          lessonId: 'lesson_1',
          lessonVersionId: 'lesson_server_v2',
          questionId: 'q_1',
          questionVersionId: 'qv1',
          selectedAnswer: 'Xin chào',
          responseTimeMs: 1200,
          usedHint: false,
          clientRequestId: 'req_stale_direct',
        ),
        throwsA(isA<StaleContentException>()),
      );

      // Verify questions cache for lesson_1 is cleared
      final questions = await database.select(database.cachedQuestions).get();
      expect(questions.isEmpty, isTrue);
    });
  });

  group('ContentRepository completeLesson Tests', () {
    setUp(() async {
      // Pre-populate a cached lesson to be completed
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_1',
          courseId: 'en_for_vi',
          title: 'Lesson 1',
          status: 'available',
          syncStatus: const Value('SYNCED'),
        ),
      );
    });

    test('success completeLesson (200) marks status=completed and syncStatus=SYNCED', () async {
      fakeDio.postHandler = <T>(path, {data}) async {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          data: {'success': true} as T,
          statusCode: 200,
        );
      };

      final result = await contentRepository.completeLesson('en_for_vi', 'lesson_1');

      expect(result, CompleteLessonResult.synced);

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_1')))
          .getSingle();
      expect(lesson.status, 'completed');
      expect(lesson.syncStatus, 'SYNCED');
    });

    test('409 LESSON_ALREADY_COMPLETED marks status=completed and syncStatus=SYNCED', () async {
      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 409,
            data: {'code': 'LESSON_ALREADY_COMPLETED', 'message': 'Already completed'},
          ),
        );
      };

      final result = await contentRepository.completeLesson('en_for_vi', 'lesson_1');

      expect(result, CompleteLessonResult.synced);

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_1')))
          .getSingle();
      expect(lesson.status, 'completed');
      expect(lesson.syncStatus, 'SYNCED');
    });

    test('422 completeLesson throws LessonIncompleteException and does not change database status', () async {
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

      expect(
        () => contentRepository.completeLesson('en_for_vi', 'lesson_1'),
        throwsA(isA<LessonIncompleteException>()),
      );

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_1')))
          .getSingle();
      expect(lesson.status, 'available'); // not changed
      expect(lesson.syncStatus, 'SYNCED'); // not changed
    });

    test('transient network exception completeLesson marks status=completed and syncStatus=PENDING', () async {
      fakeDio.postHandler = <T>(path, {data}) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionTimeout,
          message: 'Timeout',
        );
      };

      final result = await contentRepository.completeLesson('en_for_vi', 'lesson_1');

      expect(result, CompleteLessonResult.pendingOffline);

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_1')))
          .getSingle();
      expect(lesson.status, 'completed');
      expect(lesson.syncStatus, 'PENDING');
    });

    test('other transient SocketException marks status=completed and syncStatus=PENDING', () async {
      fakeDio.postHandler = <T>(path, {data}) async {
        throw const SocketException('No route to host');
      };

      final result = await contentRepository.completeLesson('en_for_vi', 'lesson_1');

      expect(result, CompleteLessonResult.pendingOffline);

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_1')))
          .getSingle();
      expect(lesson.status, 'completed');
      expect(lesson.syncStatus, 'PENDING');
    });

    test('non-transient errors (like 401) rethrow and do not change database', () async {
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

      await expectLater(
        () => contentRepository.completeLesson('en_for_vi', 'lesson_1'),
        throwsA(isA<DioException>()),
      );

      final lesson = await (database.select(database.cachedLessons)
            ..where((t) => t.courseId.equals('en_for_vi') & t.lessonId.equals('lesson_1')))
          .getSingle();
      expect(lesson.status, 'available'); // not changed
    });
  });
}
