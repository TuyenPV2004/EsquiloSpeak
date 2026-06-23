import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'lesson_providers.dart';
import '../home/home_providers.dart';
import '../../core/monitoring/monitoring_provider.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phát âm thanh: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final courseId = ref.watch(selectedCourseIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lessonAsync.valueOrNull?.title ?? 'Chi tiết bài học',
        ),
      ),
      body: lessonAsync.when(
        loading: () => const LoadingView(message: 'Đang tải nội dung bài học...'),
        error: (error, stack) => ErrorView(
          message: 'Không thể kết nối máy chủ. Vui lòng tải lại.',
          onRetry: () => ref.invalidate(lessonDetailProvider(widget.lessonId)),
        ),
        data: (lessonData) {
          if (lessonData.questions.isEmpty) {
            return const Center(child: Text('Bài học này chưa có câu hỏi nào.'));
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(monitoringServiceProvider).logEvent(
              'lesson_started',
              parameters: {
                'course_id': courseId,
                'lesson_id': widget.lessonId,
              },
            );
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Từ vựng & Cấu trúc trong bài học',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.separated(
                      itemCount: lessonData.questions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final question = lessonData.questions[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.15),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (question.audioUrl != null && question.audioUrl!.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_rounded),
                                    color: theme.colorScheme.primary,
                                    iconSize: 28,
                                    onPressed: () => _playAudio(question.audioUrl!),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Icon(Icons.description_outlined, color: Colors.grey, size: 28),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question.prompt,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (question.correctAnswer != null)
                                        Text(
                                          'Đáp án đúng: ${question.correctAnswer}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Giải thích: ${question.explanation}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/exercise/${widget.lessonId}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Luyện tập ngay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
