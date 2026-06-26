
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/shared/data/local/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Drift SQLite Database CRUD & Cache Tests', () {
    test('insert and retrieve pending attempts', () async {
      final attempt = PendingAttemptsCompanion.insert(
        clientRequestId: 'req_local_123',
        deviceId: 'device_123',
        courseId: 'en_for_vi',
        sourceLanguage: 'vi',
        targetLanguage: 'en',
        lessonId: 'lesson_1_1',
        lessonVersionId: 'lesson_v1',
        questionId: 'q_1',
        questionVersionId: 'q_v1',
        selectedAnswer: 'Xin chào',
        responseTimeMs: 1500,
        usedHint: false,
        isCorrectLocal: true,
        answeredAt: DateTime.now(),
      );

      final id = await database.into(database.pendingAttempts).insert(attempt);
      expect(id, isNotNull);

      final retrieved = await database.select(database.pendingAttempts).get();
      expect(retrieved.length, 1);
      expect(retrieved.first.clientRequestId, 'req_local_123');
      expect(retrieved.first.status, 'PENDING');
    });

    test('cache lesson details clears old cache and writes new questions/options', () async {
      // 1. Write some initial cached questions
      await database.cacheLessonDetails(
        lessonId: 'lesson_1_1',
        questions: [
          CachedQuestionsCompanion.insert(
            questionId: 'q_1',
            lessonId: 'lesson_1_1',
            prompt: 'Old Prompt',
            type: 'multiple_choice',
            correctAnswer: 'Correct',
            explanation: 'Exp',
            questionVersionId: 'v1',
          )
        ],
        options: [
          CachedQuestionOptionsCompanion.insert(
            questionId: 'q_1',
            optionId: 1,
            optionText: 'Option 1',
          )
        ],
      );

      // Verify cached questions exist
      var cachedQ = await database.select(database.cachedQuestions).get();
      expect(cachedQ.length, 1);
      expect(cachedQ.first.prompt, 'Old Prompt');

      // 2. Cache again for same lesson, should delete old and insert new
      await database.cacheLessonDetails(
        lessonId: 'lesson_1_1',
        questions: [
          CachedQuestionsCompanion.insert(
            questionId: 'q_2',
            lessonId: 'lesson_1_1',
            prompt: 'New Prompt',
            type: 'multiple_choice',
            correctAnswer: 'NewCorrect',
            explanation: 'NewExp',
            questionVersionId: 'v2',
          )
        ],
        options: [
          CachedQuestionOptionsCompanion.insert(
            questionId: 'q_2',
            optionId: 2,
            optionText: 'Option 2',
          )
        ],
      );

      // Verify old is deleted, new is present
      cachedQ = await database.select(database.cachedQuestions).get();
      expect(cachedQ.length, 1);
      expect(cachedQ.first.questionId, 'q_2');
      expect(cachedQ.first.prompt, 'New Prompt');

      final cachedOpts = await database.select(database.cachedQuestionOptions).get();
      expect(cachedOpts.length, 1);
      expect(cachedOpts.first.questionId, 'q_2');
    });

    test('invalidateLessonCache safely clears questions and options without modifying status', () async {
      // 1. Insert two cached lessons
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_a',
          courseId: 'course_1',
          title: 'Lesson A',
          status: 'completed',
          syncStatus: const Value('SYNCED'),
        ),
      );
      await database.into(database.cachedLessons).insert(
        CachedLessonsCompanion.insert(
          lessonId: 'lesson_b',
          courseId: 'course_1',
          title: 'Lesson B',
          status: 'available',
          syncStatus: const Value('SYNCED'),
        ),
      );

      // 2. Cache details for both lessons
      await database.cacheLessonDetails(
        lessonId: 'lesson_a',
        questions: [
          CachedQuestionsCompanion.insert(
            questionId: 'q_a',
            lessonId: 'lesson_a',
            prompt: 'Prompt A',
            type: 'multiple_choice',
            correctAnswer: 'A',
            explanation: 'Exp A',
            questionVersionId: 'v1',
          )
        ],
        options: [
          CachedQuestionOptionsCompanion.insert(
            questionId: 'q_a',
            optionId: 1,
            optionText: 'Option A',
          )
        ],
      );

      await database.cacheLessonDetails(
        lessonId: 'lesson_b',
        questions: [
          CachedQuestionsCompanion.insert(
            questionId: 'q_b',
            lessonId: 'lesson_b',
            prompt: 'Prompt B',
            type: 'multiple_choice',
            correctAnswer: 'B',
            explanation: 'Exp B',
            questionVersionId: 'v1',
          )
        ],
        options: [
          CachedQuestionOptionsCompanion.insert(
            questionId: 'q_b',
            optionId: 2,
            optionText: 'Option B',
          )
        ],
      );

      // 3. Invalidate lesson cache with non-existent or mismatched courseId + lessonId
      await database.invalidateLessonCache(courseId: 'course_wrong', lessonId: 'lesson_a');

      // Verify nothing is deleted
      var questions = await database.select(database.cachedQuestions).get();
      expect(questions.length, 2);

      // 4. Invalidate correct lesson cache (course_1, lesson_a)
      await database.invalidateLessonCache(courseId: 'course_1', lessonId: 'lesson_a');

      // Verify questions and options of lesson_a are deleted, but lesson_b is kept
      questions = await database.select(database.cachedQuestions).get();
      expect(questions.length, 1);
      expect(questions.first.lessonId, 'lesson_b');

      final options = await database.select(database.cachedQuestionOptions).get();
      expect(options.length, 1);
      expect(options.first.questionId, 'q_b');

      // 5. Verify lesson status in cachedLessons is NOT modified
      final lessonA = await (database.select(database.cachedLessons)
            ..where((tbl) => tbl.lessonId.equals('lesson_a')))
          .getSingle();
      expect(lessonA.status, 'completed');
      expect(lessonA.syncStatus, 'SYNCED');
    });
  });
}
