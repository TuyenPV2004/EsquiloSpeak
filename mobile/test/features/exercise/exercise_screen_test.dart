import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/src/features/exercise/exercise_screen.dart';
import 'package:mobile/src/shared/repositories/content_repository.dart';
import 'package:mobile/src/core/monitoring/monitoring_provider.dart';
import 'package:mobile/src/core/monitoring/monitoring_service.dart';
import 'package:mobile/src/features/home/home_providers.dart';
import 'package:mobile/src/shared/models/question.dart';
import 'package:mobile/src/shared/models/attempt.dart';

class StubContentRepository implements ContentRepository {
  late Future<LessonDetailResponseModel> Function(String courseId, String lessonId) getLessonDetailHandler;
  late Future<AttemptResponseModel> Function({
    required String courseId,
    required String lessonId,
    required String lessonVersionId,
    required String questionId,
    required String questionVersionId,
    required String selectedAnswer,
    required int responseTimeMs,
    required bool usedHint,
    required String clientRequestId,
  }) submitAttemptHandler;
  late Future<CompleteLessonResult> Function(String courseId, String lessonId) completeLessonHandler;

  @override
  Future<LessonDetailResponseModel> getLessonDetail(String courseId, String lessonId) {
    return getLessonDetailHandler(courseId, lessonId);
  }

  @override
  Future<AttemptResponseModel> submitAttempt({
    required String courseId,
    required String lessonId,
    required String lessonVersionId,
    required String questionId,
    required String questionVersionId,
    required String selectedAnswer,
    required int responseTimeMs,
    required bool usedHint,
    required String clientRequestId,
  }) {
    return submitAttemptHandler(
      courseId: courseId,
      lessonId: lessonId,
      lessonVersionId: lessonVersionId,
      questionId: questionId,
      questionVersionId: questionVersionId,
      selectedAnswer: selectedAnswer,
      responseTimeMs: responseTimeMs,
      usedHint: usedHint,
      clientRequestId: clientRequestId,
    );
  }

  @override
  Future<CompleteLessonResult> completeLesson(String courseId, String lessonId) {
    return completeLessonHandler(courseId, lessonId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMonitoringService implements MonitoringService {
  @override
  Future<void> init() async {}
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}
  @override
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  late StubContentRepository stubContentRepository;
  late FakeMonitoringService fakeMonitoring;
  late List<QuestionModel> mockQuestions;

  setUp(() {
    stubContentRepository = StubContentRepository();
    fakeMonitoring = FakeMonitoringService();

    mockQuestions = [
      QuestionModel(
        questionId: 'q_1',
        lessonId: 'lesson_1',
        prompt: 'What is "Xin chào" in English?',
        type: 'multiple_choice',
        correctAnswer: 'Hello',
        explanation: 'Hello means Xin chào.',
        options: [
          QuestionOptionModel(optionId: 1, optionText: 'Hello'),
          QuestionOptionModel(optionId: 2, optionText: 'Goodbye'),
        ],
      ),
      QuestionModel(
        questionId: 'q_2',
        lessonId: 'lesson_1',
        prompt: 'Say: "Good morning"',
        type: 'speaking',
        correctAnswer: 'SPOKEN_SELF_REVIEWED',
        explanation: 'Speaking practice.',
        options: [],
      ),
    ];

    stubContentRepository.getLessonDetailHandler = (courseId, lessonId) async {
      return LessonDetailResponseModel(
        lessonId: 'lesson_1',
        lessonVersionId: 'lesson_server_v2',
        title: 'Greeting Lesson',
        questions: mockQuestions,
      );
    };
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: '/lesson/lesson_1',
      routes: [
        GoRoute(
          path: '/lesson/:lessonId',
          builder: (context, state) {
            final lessonId = state.pathParameters['lessonId']!;
            return ExerciseScreen(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(stubContentRepository),
        monitoringServiceProvider.overrideWithValue(fakeMonitoring),
        selectedCourseIdProvider.overrideWith((ref) => 'en_for_vi'),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('ExerciseScreen Widget Tests', () {
    testWidgets('shows warning SnackBar when trying to complete with unanswered or incorrect questions', (WidgetTester tester) async {
      stubContentRepository.submitAttemptHandler = ({
        required courseId,
        required lessonId,
        required lessonVersionId,
        required questionId,
        required questionVersionId,
        required selectedAnswer,
        required responseTimeMs,
        required usedHint,
        required clientRequestId,
      }) async {
        return AttemptResponseModel(
          isCorrect: false, // Incorrect answer
          correctAnswer: 'Hello',
          explanation: 'Hello means Xin chào.',
          reviewCreated: false,
        );
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // We are on Q1. Select incorrect option (Goodbye)
      await tester.tap(find.text('Goodbye'));
      await tester.pumpAndSettle();

      // Click check button
      await tester.tap(find.text('Kiểm tra đáp án'));
      await tester.pumpAndSettle();

      // Verify explanation card is shown with incorrect warning
      expect(find.textContaining('Chưa chính xác!'), findsOneWidget);

      // Now click "Tiếp tục" to go to Q2
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // We are on Q2 (Speaking). Tap "Tôi đã đọc xong"
      await tester.tap(find.text('Tôi đã đọc xong'));
      await tester.pumpAndSettle();

      // Click "Hoàn thành bài học"
      await tester.tap(find.text('Hoàn thành bài học'));
      await tester.pump(); // Start animation/snack bar

      // Verify red warning SnackBar is shown because Q1 was incorrect
      expect(find.textContaining('Bài học chưa hoàn thành'), findsOneWidget);
    });

    testWidgets('allows completion when questions are correctly answered and completeLesson returns synced', (WidgetTester tester) async {
      final submittedLessonVersions = <String>[];

      stubContentRepository.submitAttemptHandler = ({
        required courseId,
        required lessonId,
        required lessonVersionId,
        required questionId,
        required questionVersionId,
        required selectedAnswer,
        required responseTimeMs,
        required usedHint,
        required clientRequestId,
      }) async {
        submittedLessonVersions.add(lessonVersionId);
        return AttemptResponseModel(
          isCorrect: true, // Correct answer
          correctAnswer: 'Hello',
          explanation: 'Hello means Xin chào.',
          reviewCreated: false,
        );
      };

      stubContentRepository.completeLessonHandler = (courseId, lessonId) async {
        return CompleteLessonResult.synced;
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Q1: Select correct option (Hello)
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      // Check
      await tester.tap(find.text('Kiểm tra đáp án'));
      await tester.pumpAndSettle();

      // Continue to Q2
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Q2 (Speaking): Complete speaking card
      await tester.tap(find.text('Tôi đã đọc xong'));
      await tester.pumpAndSettle();

      // Tap "Hoàn thành bài học"
      await tester.tap(find.text('Hoàn thành bài học'));
      await tester.pumpAndSettle();

      // Verify it navigated to Home Screen
      expect(find.text('Home Screen'), findsOneWidget);
      expect(submittedLessonVersions, ['lesson_server_v2', 'lesson_server_v2']);
    });

    testWidgets('shows orange SnackBar when completeLesson returns pendingOffline', (WidgetTester tester) async {
      stubContentRepository.submitAttemptHandler = ({
        required courseId,
        required lessonId,
        required lessonVersionId,
        required questionId,
        required questionVersionId,
        required selectedAnswer,
        required responseTimeMs,
        required usedHint,
        required clientRequestId,
      }) async {
        return AttemptResponseModel(
          isCorrect: true,
          correctAnswer: 'Hello',
          explanation: 'Hello means Xin chào.',
          reviewCreated: false,
        );
      };

      stubContentRepository.completeLessonHandler = (courseId, lessonId) async {
        return CompleteLessonResult.pendingOffline;
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Q1: Hello
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiểm tra đáp án'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Q2: Speak
      await tester.tap(find.text('Tôi đã đọc xong'));
      await tester.pumpAndSettle();

      // Tap "Hoàn thành bài học"
      await tester.tap(find.text('Hoàn thành bài học'));
      await tester.pump(); // Starts snack bar showing

      // Verify orange SnackBar
      expect(find.textContaining('Không có kết nối mạng. Bài làm đã được ghi nhận ngoại tuyến'), findsOneWidget);
      
      await tester.pumpAndSettle();
      // Verify it still navigated to Home Screen
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('shows red SnackBar and stays on screen when completeLesson throws LessonIncompleteException', (WidgetTester tester) async {
      stubContentRepository.submitAttemptHandler = ({
        required courseId,
        required lessonId,
        required lessonVersionId,
        required questionId,
        required questionVersionId,
        required selectedAnswer,
        required responseTimeMs,
        required usedHint,
        required clientRequestId,
      }) async {
        return AttemptResponseModel(
          isCorrect: true,
          correctAnswer: 'Hello',
          explanation: 'Hello means Xin chào.',
          reviewCreated: false,
        );
      };

      stubContentRepository.completeLessonHandler = (courseId, lessonId) async {
        throw LessonIncompleteException();
      };

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Q1: Hello
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiểm tra đáp án'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Q2: Speak
      await tester.tap(find.text('Tôi đã đọc xong'));
      await tester.pumpAndSettle();

      // Tap "Hoàn thành bài học"
      await tester.tap(find.text('Hoàn thành bài học'));
      await tester.pump();

      // Verify red SnackBar
      expect(find.textContaining('Bài học chưa hoàn thành: Bạn cần trả lời đúng tất cả các câu hỏi'), findsOneWidget);

      await tester.pumpAndSettle();
      // Verify it did NOT navigate to Home Screen (stays on ExerciseScreen, so "Home Screen" is not found)
      expect(find.text('Home Screen'), findsNothing);
    });
  });
}
