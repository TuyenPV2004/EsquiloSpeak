
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
  });
}
