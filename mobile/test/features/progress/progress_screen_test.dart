import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/home/home_providers.dart';
import 'package:mobile/src/features/progress/progress_screen.dart';
import 'package:mobile/src/shared/models/progress_summary.dart';
import 'package:mobile/src/shared/repositories/content_repository.dart';

class StubContentRepository implements ContentRepository {
  late Future<ProgressSummaryModel> Function(String courseId) getProgressSummaryHandler;

  @override
  Future<ProgressSummaryModel> getProgressSummary(String courseId) {
    return getProgressSummaryHandler(courseId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProgressScreen shows backend summary without fake topic mastery', (tester) async {
    final repository = StubContentRepository()
      ..getProgressSummaryHandler = (courseId) async {
        expect(courseId, 'en_for_vi');
        return ProgressSummaryModel(
          completedLessonsCount: 3,
          totalLessonsCount: 8,
          courseCompletionPercent: 37.5,
          streak: 4,
          accuracy: 82.5,
          learnedWordsCount: 27,
          dueReviewCount: 6,
        );
      };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(repository),
          selectedCourseIdProvider.overrideWith((ref) => 'en_for_vi'),
        ],
        child: const MaterialApp(
          home: ProgressScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('27'), findsOneWidget);
    expect(find.text('3/8'), findsOneWidget);
    expect(find.text('82.5%'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('37.5%'), findsOneWidget);
    expect(find.textContaining('Dữ liệu do máy chủ ghi nhận'), findsOneWidget);

    expect(find.text('Chào hỏi xã giao'), findsNothing);
    expect(find.text('Số đếm cơ bản'), findsNothing);
    expect(find.text('Gia đình & Bản thân'), findsNothing);
  });
}
