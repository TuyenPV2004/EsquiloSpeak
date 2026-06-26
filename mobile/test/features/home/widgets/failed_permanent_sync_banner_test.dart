import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/home/widgets/failed_permanent_sync_banner.dart';
import 'package:mobile/src/shared/repositories/sync_repository.dart';
import 'package:mobile/src/features/home/home_providers.dart';

class StubSyncRepository implements SyncRepository {
  late Future<void> Function() resetFailedPermanentAttemptsHandler;
  late Future<void> Function() discardFailedPermanentAttemptsHandler;
  late Future<void> Function() syncPendingAttemptsHandler;

  @override
  Future<void> resetFailedPermanentAttempts() {
    return resetFailedPermanentAttemptsHandler();
  }

  @override
  Future<void> discardFailedPermanentAttempts() {
    return discardFailedPermanentAttemptsHandler();
  }

  @override
  Future<void> syncPendingAttempts() {
    return syncPendingAttemptsHandler();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StubSyncRepository stubSyncRepository;

  setUp(() {
    stubSyncRepository = StubSyncRepository();
  });

  testWidgets('FailedPermanentSyncBanner shows correct error count and opens action dialog', (WidgetTester tester) async {
    // 1. Build the widget
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncRepositoryProvider.overrideWithValue(stubSyncRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FailedPermanentSyncBanner(count: 3),
          ),
        ),
      ),
    );

    // 2. Verify banner text
    expect(find.text('Có 3 bài làm bị lỗi đồng bộ vĩnh viễn. Nhấp để xử lý.'), findsOneWidget);

    // 3. Tap on the banner to open the dialog
    await tester.tap(find.byType(FailedPermanentSyncBanner));
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.text('Lỗi đồng bộ dữ liệu'), findsOneWidget);
    expect(find.textContaining('Hệ thống không thể tự động đồng bộ 3 bài làm'), findsOneWidget);

    // 4. Verify "Đóng" button closes the dialog
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi đồng bộ dữ liệu'), findsNothing);
  });

  testWidgets('FailedPermanentSyncBanner "Thử đồng bộ lại" calls repository reset & sync', (WidgetTester tester) async {
    bool resetCalled = false;
    bool syncCalled = false;

    stubSyncRepository.resetFailedPermanentAttemptsHandler = () async {
      resetCalled = true;
    };
    stubSyncRepository.syncPendingAttemptsHandler = () async {
      syncCalled = true;
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncRepositoryProvider.overrideWithValue(stubSyncRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FailedPermanentSyncBanner(count: 3),
          ),
        ),
      ),
    );

    // Open Dialog
    await tester.tap(find.byType(FailedPermanentSyncBanner));
    await tester.pumpAndSettle();

    // Tap "Thử đồng bộ lại"
    await tester.tap(find.text('Thử đồng bộ lại'));
    await tester.pumpAndSettle();

    expect(resetCalled, isTrue);
    expect(syncCalled, isTrue);
    expect(find.text('Lỗi đồng bộ dữ liệu'), findsNothing);
  });

  testWidgets('FailedPermanentSyncBanner "Hủy bỏ bài làm lỗi" prompts confirm dialog and triggers discard', (WidgetTester tester) async {
    bool discardCalled = false;

    stubSyncRepository.discardFailedPermanentAttemptsHandler = () async {
      discardCalled = true;
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncRepositoryProvider.overrideWithValue(stubSyncRepository),
          courseHomeProvider.overrideWith((ref) => throw UnimplementedError()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FailedPermanentSyncBanner(count: 3),
          ),
        ),
      ),
    );

    // Open first Dialog
    await tester.tap(find.byType(FailedPermanentSyncBanner));
    await tester.pumpAndSettle();

    // Tap "Hủy bỏ bài làm lỗi" to open confirmation dialog
    await tester.tap(find.text('Hủy bỏ bài làm lỗi'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Xác nhận hủy bỏ'), findsOneWidget);
    expect(find.textContaining('Hành động này không thể hoàn tác'), findsOneWidget);

    // Tap "Đồng ý hủy"
    await tester.tap(find.text('Đồng ý hủy'));
    await tester.pumpAndSettle();

    expect(discardCalled, isTrue);
    expect(find.text('Xác nhận hủy bỏ'), findsNothing);
  });
}
