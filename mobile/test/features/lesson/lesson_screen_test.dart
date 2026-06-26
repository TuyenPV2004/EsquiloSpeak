import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/lesson/lesson_screen.dart';
import 'package:mobile/src/features/lesson/lesson_providers.dart';
import 'package:mobile/src/features/home/home_providers.dart';
import 'package:mobile/src/shared/repositories/content_repository.dart';
import 'package:mobile/src/shared/models/question.dart';
import 'package:mobile/src/core/monitoring/monitoring_provider.dart';
import 'package:mobile/src/core/monitoring/monitoring_service.dart';

class StubContentRepository implements ContentRepository {
  late Future<LessonDetailResponseModel> Function(String courseId, String lessonId) getLessonDetailHandler;

  @override
  Future<LessonDetailResponseModel> getLessonDetail(String courseId, String lessonId) {
    return getLessonDetailHandler(courseId, lessonId);
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

  setUp(() {
    stubContentRepository = StubContentRepository();
    fakeMonitoring = FakeMonitoringService();
  });

  testWidgets('LessonScreen displays prompts but hides correctAnswer and explanation', (WidgetTester tester) async {
    // 1. Setup mock data
    final mockLesson = LessonDetailResponseModel(
      lessonId: 'lesson_123',
      lessonVersionId: 'v1',
      title: 'Mock Lesson Title',
      questions: [
        QuestionModel(
          questionId: 'q_1',
          lessonId: 'lesson_123',
          prompt: 'Test Prompt 1',
          type: 'multiple_choice',
          correctAnswer: 'Secret Answer 1',
          explanation: 'Detailed Explanation 1',
          options: [],
        ),
      ],
    );

    stubContentRepository.getLessonDetailHandler = (courseId, lessonId) async => mockLesson;

    // 2. Build the widget inside ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(stubContentRepository),
          monitoringServiceProvider.overrideWithValue(fakeMonitoring),
          selectedCourseIdProvider.overrideWith((ref) => 'en_for_vi'),
        ],
        child: const MaterialApp(
          home: LessonScreen(lessonId: 'lesson_123'),
        ),
      ),
    );

    // Chờ data load xong
    await tester.pumpAndSettle();

    // 3. Verify assertions
    expect(find.text('Mock Lesson Title'), findsOneWidget);
    expect(find.text('Test Prompt 1'), findsOneWidget);
    
    // Đảm bảo không tồn tại text đáp án và giải thích
    expect(find.textContaining('Secret Answer 1'), findsNothing);
    expect(find.textContaining('Detailed Explanation 1'), findsNothing);
    expect(find.textContaining('Đáp án đúng'), findsNothing);
    expect(find.textContaining('Giải thích'), findsNothing);
  });
}
