import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/repositories/content_repository.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/models/review_item.dart';
import '../home/home_providers.dart';
import 'review_providers.dart';
import '../../core/monitoring/monitoring_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _currentIndex = 0;
  bool _showMeaning = false;
  bool _isSubmitting = false;
  late DateTime _startTime;
  final List<ReviewItemModel> _sessionQueue = [];
  bool _isInitialized = false;
  bool _isSessionCompletedLogged = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _submitRating(
    String courseId,
    String reviewItemId,
    String rating,
    int responseTimeMs,
    ReviewItemModel currentItem,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(contentRepositoryProvider);
      await repository.submitReviewAttempt(
        courseId: courseId,
        reviewItemId: reviewItemId,
        rating: rating,
        responseTimeMs: responseTimeMs,
      );

      setState(() {
        if (rating == 'again') {
          _sessionQueue.add(currentItem);
        }
        _currentIndex++;
        _showMeaning = false;
        _startTime = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi đánh giá: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseId = ref.watch(selectedCourseIdProvider);
    final dueReviewsAsync = ref.watch(dueReviewsProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ôn tập từ vựng'),
      ),
      body: dueReviewsAsync.when(
        loading: () => const LoadingView(message: 'Đang tải hàng đợi ôn tập...'),
        error: (error, stack) => ErrorView(
          message: 'Không thể tải dữ liệu ôn tập. Vui lòng thử lại.',
          onRetry: () => ref.invalidate(dueReviewsProvider(courseId)),
        ),
        data: (dueReviews) {
          if (dueReviews.isEmpty && !_isInitialized) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.spa_rounded,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tuyệt vời! Bạn không có từ vựng nào cần ôn tập hôm nay.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Quay lại Trang chủ'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!_isInitialized) {
            _sessionQueue.addAll(dueReviews);
            _isInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(monitoringServiceProvider).logEvent(
                'review_started',
                parameters: {
                  'course_id': courseId,
                  'total_due': dueReviews.length,
                },
              );
            });
          }

          if (_currentIndex >= _sessionQueue.length) {
            if (!_isSessionCompletedLogged) {
              _isSessionCompletedLogged = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(monitoringServiceProvider).logEvent(
                  'review_completed',
                  parameters: {
                    'course_id': courseId,
                    'cards_count': _sessionQueue.length,
                  },
                );
              });
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hoàn thành phiên ôn tập!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn đã hoàn thành việc ôn tập tất cả các từ đến hạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(courseHomeProvider);
                        context.go('/home');
                      },
                      child: const Text('Quay lại Trang chủ'),
                    ),
                  ],
                ),
              ),
            );
          }

          final item = _sessionQueue[_currentIndex];
          final progressText = 'Thẻ thứ ${_currentIndex + 1}/${_sessionQueue.length}';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    progressText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Thẻ Flashcard từ vựng
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded),
                              color: theme.colorScheme.primary,
                              iconSize: 48,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Phát âm: "${item.concept}"'),
                                    duration: const Duration(milliseconds: 500),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item.concept,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            
                            // Nghĩa hiển thị khi được bật
                            if (_showMeaning) ...[
                              Text(
                                item.correctAnswer,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (item.explanation.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    item.explanation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ] else ...[
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : () {
                                  setState(() {
                                    _showMeaning = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                  foregroundColor: theme.colorScheme.secondary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Xem nghĩa'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 4 nút tự đánh giá chất lượng ôn tập (SM-2 inspired options)
                  if (_showMeaning) ...[
                    Text(
                      'Mức độ ghi nhớ của bạn thế nào?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeedbackButton(context, 'Chưa nhớ', 'Again', Colors.red, () {
                          if (_isSubmitting) return;
                          final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
                          _submitRating(courseId, item.reviewItemId, 'again', elapsed, item);
                        }),
                        _buildFeedbackButton(context, 'Hơi khó', 'Hard', Colors.orange, () {
                          if (_isSubmitting) return;
                          final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
                          _submitRating(courseId, item.reviewItemId, 'hard', elapsed, item);
                        }),
                        _buildFeedbackButton(context, 'Tốt', 'Good', Colors.blue, () {
                          if (_isSubmitting) return;
                          final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
                          _submitRating(courseId, item.reviewItemId, 'good', elapsed, item);
                        }),
                        _buildFeedbackButton(context, 'Dễ', 'Easy', Colors.green, () {
                          if (_isSubmitting) return;
                          final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
                          _submitRating(courseId, item.reviewItemId, 'easy', elapsed, item);
                        }),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 60), // Khoảng trống giữ nguyên chiều cao bố cục
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackButton(
    BuildContext context, 
    String title, 
    String code, 
    Color color, 
    VoidCallback onTap
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.4)),
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
