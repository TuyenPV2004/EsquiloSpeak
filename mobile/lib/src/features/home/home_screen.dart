import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_providers.dart';
import '../progress/progress_providers.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/repositories/sync_repository.dart';

final pendingAttemptsCountProvider = StreamProvider<int>((ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  return syncRepo.watchPendingCount();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger sync on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncRepositoryProvider).syncPendingAttempts().catchError((e) {
        debugPrint('Auto sync failed: $e');
      });
    });

    final theme = Theme.of(context);
    final homeAsync = ref.watch(courseHomeProvider);
    final courseId = ref.watch(selectedCourseIdProvider);
    final progressAsync = ref.watch(progressSummaryProvider(courseId));
    final pendingCountAsync = ref.watch(pendingAttemptsCountProvider);
    final pendingCount = pendingCountAsync.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EsquiloSpeak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            onPressed: () => context.push('/progress'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const LoadingView(message: 'Đang tải thông tin khóa học...'),
        error: (error, stack) => ErrorView(
          message: 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng hoặc khởi chạy backend.',
          onRetry: () => ref.invalidate(courseHomeProvider),
        ),
        data: (homeData) {
          if (homeData.lessons.isEmpty) {
            return const Center(child: Text('Chưa có bài học nào được cấu hình cho khóa học này.'));
          }

          final nextLesson = homeData.lessons.first;
          final progressData = progressAsync.value;
          final streakText = progressData != null ? '${progressData.streak} ngày' : '-- ngày';
          final learnedWordsText = progressData != null ? '${progressData.learnedWordsCount} từ' : '-- từ';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(courseHomeProvider);
              ref.invalidate(progressSummaryProvider(courseId));
              try {
                await ref.read(syncRepositoryProvider).syncPendingAttempts();
              } catch (e) {
                debugPrint('Sync failed during refresh: $e');
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pendingCount > 0) ...[
                      GestureDetector(
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đang đồng bộ bài làm...'), duration: Duration(seconds: 1)),
                          );
                          try {
                            await ref.read(syncRepositoryProvider).syncPendingAttempts();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đồng bộ thành công!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đồng bộ thất bại: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sync_problem_rounded, color: Colors.amber.shade900),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Bạn có $pendingCount bài làm chưa đồng bộ. Nhấp để đồng bộ ngay.',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Colors.amber.shade900),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Hôm nay cần học gì?
                    Text(
                      'Học gì hôm nay?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Học phần chính (Lesson Card)
                    Card(
                      elevation: 4,
                      shadowColor: theme.colorScheme.primary.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'BÀI HỌC TIẾP THEO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                homeData.activeUnitTitle ?? 'Chương học hiện tại',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nextLesson.title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => context.push('/lesson/${nextLesson.lessonId}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Học ngay (5-10 phút)'),
                                    SizedBox(width: 8),
                                    Icon(Icons.play_arrow_rounded),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Ôn tập ngắt quãng (Review Card)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.repeat_rounded,
                                color: Colors.amber,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hộp ôn tập (Due)',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bạn có ${homeData.dueReviewCount} từ vựng cần ôn hôm nay.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => context.push('/review'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Ôn tập'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Danh sách bài học
                    Text(
                      'Danh sách bài học',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: homeData.lessons.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lesson = homeData.lessons[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            lesson.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('Trạng thái: ${lesson.status == 'available' ? 'Có sẵn' : lesson.status}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/lesson/${lesson.lessonId}'),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    // Thông tin học tập
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context, 
                            streakText, 
                            'Streak hiện tại', 
                            Icons.local_fire_department_rounded, 
                            Colors.orange
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context, 
                            learnedWordsText, 
                            'Đã tích lũy', 
                            Icons.inventory_2_rounded, 
                            Colors.blue
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String value, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
