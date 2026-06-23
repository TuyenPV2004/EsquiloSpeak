import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/shared/models/course.dart';
import 'package:mobile/src/shared/models/course_home.dart';
import 'package:mobile/src/shared/models/question.dart';
import 'package:mobile/src/shared/models/attempt.dart';
import 'package:mobile/src/shared/models/review_item.dart';
import 'package:mobile/src/shared/models/progress_summary.dart';

void main() {
  group('Content Models JSON Parsing', () {
    test('CourseModel.fromJson parses course data', () {
      final json = {
        'courseId': 'en_for_vi',
        'title': 'Tiếng Anh Giao Tiếp Căn Bản',
        'sourceLanguage': 'vi',
        'targetLanguage': 'en',
        'level': 'A0-A1',
        'createdAt': '2026-06-23T05:00:00'
      };

      final course = CourseModel.fromJson(json);
      expect(course.courseId, 'en_for_vi');
      expect(course.title, 'Tiếng Anh Giao Tiếp Căn Bản');
      expect(course.sourceLanguage, 'vi');
      expect(course.targetLanguage, 'en');
      expect(course.level, 'A0-A1');
      expect(course.createdAt, isNotNull);
    });

    test('CourseHomeModel.fromJson parses home response', () {
      final json = {
        'courseId': 'en_for_vi',
        'activeUnitId': 'unit_1',
        'activeUnitTitle': 'Greetings and Introductions',
        'progressPercent': 0,
        'lessons': [
          {'lessonId': 'lesson_1_1', 'title': 'Chào hỏi cơ bản', 'status': 'available'},
          {'lessonId': 'lesson_1_2', 'title': 'Giới thiệu bản thân', 'status': 'available'}
        ],
        'dueReviewCount': 5
      };

      final home = CourseHomeModel.fromJson(json);
      expect(home.courseId, 'en_for_vi');
      expect(home.activeUnitId, 'unit_1');
      expect(home.activeUnitTitle, 'Greetings and Introductions');
      expect(home.lessons.length, 2);
      expect(home.lessons[0].lessonId, 'lesson_1_1');
      expect(home.lessons[0].title, 'Chào hỏi cơ bản');
      expect(home.dueReviewCount, 5);
    });

    test('LessonDetailResponseModel.fromJson parses lesson questions', () {
      final json = {
        'lessonId': 'lesson_1_1',
        'lessonVersionId': 'lesson_1_1_v1',
        'title': 'Chào hỏi cơ bản',
        'questions': [
          {
            'questionId': 'q_111',
            'lessonId': 'lesson_1_1',
            'prompt': 'Dịch câu sau: \'Hello\'',
            'type': 'multiple_choice',
            'audioUrl': 'http://localhost:8080/api/v1/media/hello.mp3',
            'correctAnswer': 'Xin chào',
            'explanation': '\'Hello\' nghĩa là \'Xin chào\' trong tiếng Anh.',
            'versionId': 'q_111_v1',
            'options': [
              {'optionId': 1, 'optionText': 'Xin chào'},
              {'optionId': 2, 'optionText': 'Tạm biệt'}
            ]
          }
        ]
      };

      final detail = LessonDetailResponseModel.fromJson(json);
      expect(detail.lessonId, 'lesson_1_1');
      expect(detail.title, 'Chào hỏi cơ bản');
      expect(detail.questions.length, 1);
      expect(detail.questions[0].questionId, 'q_111');
      expect(detail.questions[0].options.length, 2);
      expect(detail.questions[0].options[0].optionText, 'Xin chào');
    });

    test('AttemptResponseModel.fromJson parses attempt response', () {
      final json = {
        'isCorrect': true,
        'correctAnswer': 'Xin chào',
        'explanation': '\'Hello\' nghĩa là \'Xin chào\' trong tiếng Anh.',
        'reviewCreated': true
      };

      final attempt = AttemptResponseModel.fromJson(json);
      expect(attempt.isCorrect, true);
      expect(attempt.correctAnswer, 'Xin chào');
      expect(attempt.explanation, '\'Hello\' nghĩa là \'Xin chào\' trong tiếng Anh.');
      expect(attempt.reviewCreated, true);
    });

    test('ReviewItemModel.fromJson parses review item data', () {
      final json = {
        'reviewItemId': 'rev_123',
        'userId': 'user_abc',
        'courseId': 'en_for_vi',
        'concept': 'Hello',
        'type': 'vocabulary',
        'easeFactor': 2.5,
        'intervalDays': 1,
        'repetitionCount': 1,
        'nextReviewAt': '2026-06-23T15:00:00.000',
        'correctAnswer': 'Xin chào',
        'explanation': '\'Hello\' nghĩa là \'Xin chào\' trong tiếng Anh.'
      };

      final reviewItem = ReviewItemModel.fromJson(json);
      expect(reviewItem.reviewItemId, 'rev_123');
      expect(reviewItem.userId, 'user_abc');
      expect(reviewItem.courseId, 'en_for_vi');
      expect(reviewItem.concept, 'Hello');
      expect(reviewItem.type, 'vocabulary');
      expect(reviewItem.easeFactor, 2.5);
      expect(reviewItem.intervalDays, 1);
      expect(reviewItem.repetitionCount, 1);
      expect(reviewItem.nextReviewAt.year, 2026);
      expect(reviewItem.correctAnswer, 'Xin chào');
      expect(reviewItem.explanation, '\'Hello\' nghĩa là \'Xin chào\' trong tiếng Anh.');
    });

    test('ProgressSummaryModel.fromJson parses progress stats', () {
      final json = {
        'completedLessonsCount': 2,
        'totalLessonsCount': 4,
        'courseCompletionPercent': 50.0,
        'streak': 3,
        'accuracy': 85.5,
        'learnedWordsCount': 8,
        'dueReviewCount': 2
      };

      final progress = ProgressSummaryModel.fromJson(json);
      expect(progress.completedLessonsCount, 2);
      expect(progress.totalLessonsCount, 4);
      expect(progress.courseCompletionPercent, 50.0);
      expect(progress.streak, 3);
      expect(progress.accuracy, 85.5);
      expect(progress.learnedWordsCount, 8);
      expect(progress.dueReviewCount, 2);
    });
  });
}
