import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../data/local/app_database.dart';
import '../data/local/database_provider.dart';
import '../models/course.dart';
import '../models/course_home.dart';
import '../models/question.dart';
import '../models/attempt.dart';
import '../models/review_item.dart';
import '../models/progress_summary.dart';

class OfflineModeException implements Exception {
  final bool isCorrectLocal;
  final String correctAnswer;
  final String explanation;
  final String message;

  OfflineModeException({
    required this.isCorrectLocal,
    required this.correctAnswer,
    required this.explanation,
    required this.message,
  });

  @override
  String toString() => message;
}

class ContentRepository {
  final Dio _dio;
  final AppDatabase _db;

  ContentRepository(this._dio, this._db);

  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await _dio.get('/api/v1/courses');
      final list = response.data as List;
      final courses = list.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
      
      // Save courses to local DB
      for (final c in courses) {
        await _db.into(_db.cachedCourses).insertOnConflictUpdate(
          CachedCoursesCompanion(
            courseId: Value(c.courseId),
            title: Value(c.title),
            sourceLanguage: Value(c.sourceLanguage),
            targetLanguage: Value(c.targetLanguage),
            level: Value(c.level),
          ),
        );
      }
      return courses;
    } catch (e) {
      if (e is DioException || e is SocketException) {
        final cached = await _db.select(_db.cachedCourses).get();
        if (cached.isNotEmpty) {
          return cached.map((c) => CourseModel(
            courseId: c.courseId,
            title: c.title,
            sourceLanguage: c.sourceLanguage,
            targetLanguage: c.targetLanguage,
            level: c.level,
          )).toList();
        }
      }
      rethrow;
    }
  }

  Future<CourseHomeModel> getCourseHome(String courseId) async {
    try {
      final response = await _dio.get('/api/v1/courses/$courseId/home');
      final data = CourseHomeModel.fromJson(response.data as Map<String, dynamic>);
      
      // Update cached lessons
      await _db.transaction(() async {
        for (final l in data.lessons) {
          await _db.into(_db.cachedLessons).insertOnConflictUpdate(
            CachedLessonsCompanion(
              lessonId: Value(l.lessonId),
              courseId: Value(courseId),
              title: Value(l.title),
              status: Value(l.status),
            ),
          );
        }
      });
      return data;
    } catch (e) {
      if (e is DioException || e is SocketException) {
        final cached = await (_db.select(_db.cachedLessons)
              ..where((tbl) => tbl.courseId.equals(courseId)))
            .get();
        if (cached.isNotEmpty) {
          return CourseHomeModel(
            courseId: courseId,
            progressPercent: 0,
            activeUnitTitle: 'Bài học ngoại tuyến',
            lessons: cached.map((l) => LessonInfoModel(
              lessonId: l.lessonId,
              title: l.title,
              status: l.status,
            )).toList(),
            dueReviewCount: 0,
          );
        }
      }
      rethrow;
    }
  }

  String _resolveApiUrl(String baseUrl, String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = pathOrUrl.startsWith('/')
        ? pathOrUrl
        : '/$pathOrUrl';

    return '$normalizedBase$normalizedPath';
  }

  Future<LessonDetailResponseModel> getLessonDetail(String courseId, String lessonId) async {
    try {
      final response = await _dio.get('/api/v1/courses/$courseId/lessons/$lessonId');
      final data = LessonDetailResponseModel.fromJson(response.data as Map<String, dynamic>);

      // Cache the questions and options
      final questionsCompanions = data.questions.map((q) => CachedQuestionsCompanion(
        questionId: Value(q.questionId),
        lessonId: Value(q.lessonId),
        prompt: Value(q.prompt),
        type: Value(q.type),
        audioUrl: Value(q.audioUrl),
        correctAnswer: Value(q.correctAnswer ?? ''),
        explanation: Value(q.explanation ?? ''),
        questionVersionId: Value(q.versionId ?? '${q.questionId}_v1'),
      )).toList();

      final optionsCompanions = <CachedQuestionOptionsCompanion>[];
      for (final q in data.questions) {
        for (var i = 0; i < q.options.length; i++) {
          final opt = q.options[i];
          optionsCompanions.add(CachedQuestionOptionsCompanion(
            questionId: Value(q.questionId),
            optionId: Value(opt.optionId ?? i),
            optionText: Value(opt.optionText),
          ));
        }
      }

      await _db.cacheLessonDetails(
        lessonId: lessonId,
        questions: questionsCompanions,
        options: optionsCompanions,
      );

      // Also cache the lesson itself in CachedLessons
      await _db.into(_db.cachedLessons).insertOnConflictUpdate(
        CachedLessonsCompanion(
          lessonId: Value(lessonId),
          courseId: Value(courseId),
          title: Value(data.title),
          status: const Value('available'),
        )
      );

      // Resolve audioUrl for each question
      final resolvedQuestions = data.questions.map((q) {
        if (q.audioUrl != null && q.audioUrl!.isNotEmpty) {
          final resolvedUrl = _resolveApiUrl(_dio.options.baseUrl ?? '', q.audioUrl!);
          return QuestionModel(
            questionId: q.questionId,
            lessonId: q.lessonId,
            prompt: q.prompt,
            type: q.type,
            audioUrl: resolvedUrl,
            correctAnswer: q.correctAnswer,
            explanation: q.explanation,
            versionId: q.versionId,
            options: q.options,
          );
        }
        return q;
      }).toList();

      return LessonDetailResponseModel(
        lessonId: data.lessonId,
        lessonVersionId: data.lessonVersionId,
        title: data.title,
        questions: resolvedQuestions,
      );
    } catch (e) {
      if (e is DioException || e is SocketException) {
        final cachedQuestionsList = await (_db.select(_db.cachedQuestions)
              ..where((tbl) => tbl.lessonId.equals(lessonId)))
            .get();

        if (cachedQuestionsList.isEmpty) {
          throw Exception('Bài học này chưa được tải để học ngoại tuyến. Vui lòng kết nối mạng để tải.');
        }

        final questions = <QuestionModel>[];
        for (final cq in cachedQuestionsList) {
          final cachedOpts = await (_db.select(_db.cachedQuestionOptions)
                ..where((tbl) => tbl.questionId.equals(cq.questionId)))
              .get();

          final options = cachedOpts.map((co) => QuestionOptionModel(
            optionId: co.optionId,
            optionText: co.optionText,
          )).toList();

          final resolvedUrl = cq.audioUrl != null && cq.audioUrl!.isNotEmpty
              ? _resolveApiUrl(_dio.options.baseUrl ?? '', cq.audioUrl!)
              : cq.audioUrl;

          questions.add(QuestionModel(
            questionId: cq.questionId,
            lessonId: cq.lessonId,
            prompt: cq.prompt,
            type: cq.type,
            audioUrl: resolvedUrl,
            correctAnswer: cq.correctAnswer,
            explanation: cq.explanation,
            versionId: cq.questionVersionId,
            options: options,
          ));
        }

        final cachedLesson = await (_db.select(_db.cachedLessons)
              ..where((tbl) => tbl.lessonId.equals(lessonId)))
            .getSingleOrNull();

        final title = cachedLesson?.title ?? 'Bài học (Offline)';

        return LessonDetailResponseModel(
          lessonId: lessonId,
          lessonVersionId: '${lessonId}_v1',
          title: title,
          questions: questions,
        );
      }
      rethrow;
    }
  }

  Future<AttemptResponseModel> submitAttempt({
    required String courseId,
    required String lessonId,
    required String questionId,
    required String questionVersionId,
    required String selectedAnswer,
    required int responseTimeMs,
    required bool usedHint,
    required String clientRequestId,
  }) async {
    final now = DateTime.now();
    // Look up languages from Cache or default
    final cachedCourse = await (_db.select(_db.cachedCourses)..where((tbl) => tbl.courseId.equals(courseId))).getSingleOrNull();
    final sourceLang = cachedCourse?.sourceLanguage ?? 'vi';
    final targetLang = cachedCourse?.targetLanguage ?? 'en';

    final payload = {
      'clientRequestId': clientRequestId,
      'deviceId': 'device_mock_id',
      'courseId': courseId,
      'sourceLanguage': sourceLang,
      'targetLanguage': targetLang,
      'lessonId': lessonId,
      'lessonVersionId': '${lessonId}_v1',
      'questionId': questionId,
      'questionVersionId': questionVersionId,
      'selectedAnswer': selectedAnswer,
      'responseTimeMs': responseTimeMs,
      'usedHint': usedHint,
      'answeredAt': now.toIso8601String(),
    };

    try {
      final response = await _dio.post(
        '/api/v1/courses/$courseId/attempts',
        data: payload,
      );
      return AttemptResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (de) {
      final isTransient = de.type == DioExceptionType.connectionTimeout ||
          de.type == DioExceptionType.sendTimeout ||
          de.type == DioExceptionType.receiveTimeout ||
          de.type == DioExceptionType.connectionError ||
          (de.response != null && de.response!.statusCode != null && de.response!.statusCode! >= 500);

      if (isTransient) {
        final cachedQ = await (_db.select(_db.cachedQuestions)..where((tbl) => tbl.questionId.equals(questionId))).getSingleOrNull();
        final bool isCorrectLocal = cachedQ != null && (
          cachedQ.type == 'speaking'
          ? true
          : cachedQ.correctAnswer.trim().toLowerCase() == selectedAnswer.trim().toLowerCase()
        );
        final String explanation = cachedQ?.explanation ?? '';
        final String correctAnswer = cachedQ?.correctAnswer ?? '';

        await _db.into(_db.pendingAttempts).insertOnConflictUpdate(
          PendingAttemptsCompanion(
            clientRequestId: Value(clientRequestId),
            deviceId: const Value('device_mock_id'),
            courseId: Value(courseId),
            sourceLanguage: Value(sourceLang),
            targetLanguage: Value(targetLang),
            lessonId: Value(lessonId),
            lessonVersionId: Value('${lessonId}_v1'),
            questionId: Value(questionId),
            questionVersionId: Value(questionVersionId),
            selectedAnswer: Value(selectedAnswer),
            responseTimeMs: Value(responseTimeMs),
            usedHint: Value(usedHint),
            isCorrectLocal: Value(isCorrectLocal),
            answeredAt: Value(now),
            status: const Value('PENDING'),
          ),
        );

        throw OfflineModeException(
          isCorrectLocal: isCorrectLocal,
          correctAnswer: correctAnswer,
          explanation: explanation,
          message: 'Không có kết nối mạng. Bài làm đã được lưu offline.',
        );
      }
      rethrow;
    } catch (e) {
      if (e is SocketException) {
        final cachedQ = await (_db.select(_db.cachedQuestions)..where((tbl) => tbl.questionId.equals(questionId))).getSingleOrNull();
        final bool isCorrectLocal = cachedQ != null && (
          cachedQ.type == 'speaking'
          ? true
          : cachedQ.correctAnswer.trim().toLowerCase() == selectedAnswer.trim().toLowerCase()
        );
        final String explanation = cachedQ?.explanation ?? '';
        final String correctAnswer = cachedQ?.correctAnswer ?? '';

        await _db.into(_db.pendingAttempts).insertOnConflictUpdate(
          PendingAttemptsCompanion(
            clientRequestId: Value(clientRequestId),
            deviceId: const Value('device_mock_id'),
            courseId: Value(courseId),
            sourceLanguage: Value(sourceLang),
            targetLanguage: Value(targetLang),
            lessonId: Value(lessonId),
            lessonVersionId: Value('${lessonId}_v1'),
            questionId: Value(questionId),
            questionVersionId: Value(questionVersionId),
            selectedAnswer: Value(selectedAnswer),
            responseTimeMs: Value(responseTimeMs),
            usedHint: Value(usedHint),
            isCorrectLocal: Value(isCorrectLocal),
            answeredAt: Value(now),
            status: const Value('PENDING'),
          ),
        );

        throw OfflineModeException(
          isCorrectLocal: isCorrectLocal,
          correctAnswer: correctAnswer,
          explanation: explanation,
          message: 'Không có kết nối mạng. Bài làm đã được lưu offline.',
        );
      }
      rethrow;
    }
  }

  Future<List<ReviewItemModel>> getDueReviews(String courseId) async {
    final response = await _dio.get('/api/v1/courses/$courseId/reviews/due');
    final list = response.data as List;
    return list.map((e) => ReviewItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitReviewAttempt({
    required String courseId,
    required String reviewItemId,
    required String rating,
    required int responseTimeMs,
  }) async {
    final payload = {
      'reviewItemId': reviewItemId,
      'rating': rating,
      'responseTimeMs': responseTimeMs,
    };
    await _dio.post(
      '/api/v1/courses/$courseId/review-attempts',
      data: payload,
    );
  }

  Future<void> completeLesson(String courseId, String lessonId) async {
    await _dio.post('/api/v1/courses/$courseId/lessons/$lessonId/complete');
  }

  Future<ProgressSummaryModel> getProgressSummary(String courseId) async {
    final response = await _dio.get('/api/v1/courses/$courseId/progress/summary');
    return ProgressSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  return ContentRepository(dio, db);
});
