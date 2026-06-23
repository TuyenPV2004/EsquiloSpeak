import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_providers.dart';
import 'progress_providers.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final courseId = ref.watch(selectedCourseIdProvider);
    final progressAsync = ref.watch(progressSummaryProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiến trình học tập'),
      ),
      body: progressAsync.when(
        loading: () => const LoadingView(message: 'Đang tải thống kê tiến trình...'),
        error: (error, stack) => ErrorView(
          message: 'Không thể kết nối máy chủ. Vui lòng tải lại.',
          onRetry: () => ref.invalidate(progressSummaryProvider(courseId)),
        ),
        data: (data) {
          final showMasteryUnit1 = data.courseCompletionPercent / 100.0;
          final showMasteryUnit2 = data.courseCompletionPercent > 50 
              ? ((data.courseCompletionPercent - 50) * 2) / 100.0 
              : 0.0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(progressSummaryProvider(courseId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Trạng thái Streak hàng ngày
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.streak > 0 
                                        ? 'Chuỗi học ${data.streak} ngày!' 
                                        : 'Chưa có chuỗi học nào',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.streak > 0
                                        ? 'Bạn đang làm rất tốt, duy trì đều đặn nhé!'
                                        : 'Hãy bắt đầu bài học đầu tiên để tạo chuỗi học ngay!',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Thống kê chi tiết học tập
                    Text(
                      'Thống kê tích lũy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            context, 
                            '${data.learnedWordsCount}', 
                            'Từ vựng đã học', 
                            Icons.menu_book_rounded, 
                            theme.colorScheme.primary
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatTile(
                            context, 
                            '${data.completedLessonsCount}', 
                            'Bài học đã làm', 
                            Icons.check_circle_rounded, 
                            Colors.green
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            context, 
                            '${data.accuracy.toStringAsFixed(1)}%', 
                            'Độ chính xác', 
                            Icons.gps_fixed_rounded, 
                            Colors.blue
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatTile(
                            context, 
                            '${data.dueReviewCount}', 
                            'Đang chờ ôn', 
                            Icons.history_rounded, 
                            Colors.amber
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Trạng thái Mastery (Mức độ thành thạo)
                    Text(
                      'Độ thành thạo theo chủ đề',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildMasteryBar(context, 'Chào hỏi xã giao', showMasteryUnit1),
                            const Divider(height: 24),
                            _buildMasteryBar(context, 'Số đếm cơ bản', showMasteryUnit2),
                            const Divider(height: 24),
                            _buildMasteryBar(context, 'Gia đình & Bản thân', 0.0),
                          ],
                        ),
                      ),
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

  Widget _buildStatTile(
    BuildContext context, 
    String value, 
    String label, 
    IconData icon, 
    Color color
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryBar(BuildContext context, String topic, double value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topic,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: theme.colorScheme.surfaceVariant,
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}
