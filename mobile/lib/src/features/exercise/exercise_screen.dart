import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/src/core/ui/root_scaffold_messenger.dart';
import '../lesson/lesson_providers.dart';
import '../home/home_providers.dart';
import '../progress/progress_providers.dart';
import '../../shared/models/question.dart';
import '../../shared/repositories/content_repository.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/listen_and_repeat_card.dart';
import '../../core/monitoring/monitoring_provider.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const ExerciseScreen({super.key, required this.lessonId});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isSubmitting = false;
  bool _isCorrect = false;
  final Map<String, bool> _questionCorrectness = {};
  final Set<String> _answeredQuestionIds = {};
  String _correctAnswer = '';
  String _explanation = '';
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _submitAnswer(String courseId, String questionId, String questionVersionId, String selectedAnswer, String questionType) async {
    setState(() {
      _isSubmitting = true;
    });

    final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
    final random = Random();
    final clientReqId = 'crq_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}';

    try {
      final repository = ref.read(contentRepositoryProvider);
      final response = await repository.submitAttempt(
        courseId: courseId,
        lessonId: widget.lessonId,
        questionId: questionId,
        questionVersionId: questionVersionId,
        selectedAnswer: selectedAnswer,
        responseTimeMs: elapsed,
        usedHint: false,
        clientRequestId: clientReqId,
      );

      setState(() {
        _isCorrect = response.isCorrect;
        _correctAnswer = response.correctAnswer;
        _explanation = response.explanation;
        _isChecked = true;
        _answeredQuestionIds.add(questionId);
        _questionCorrectness[questionId] = (questionType == 'speaking') ? true : response.isCorrect;
      });

      // Log question_answered event
      String responseTimeBucket = '0_5s';
      if (elapsed >= 30000) {
        responseTimeBucket = '30s_plus';
      } else if (elapsed >= 15000) {
        responseTimeBucket = '15_30s';
      } else if (elapsed >= 5000) {
        responseTimeBucket = '5_15s';
      }

      final resultCategory = questionType == 'speaking'
          ? 'completion_only'
          : (response.isCorrect ? 'correct' : 'incorrect');

      ref.read(monitoringServiceProvider).logEvent(
        'question_answered',
        parameters: {
          'course_id': courseId,
          'lesson_id': widget.lessonId,
          'question_type': questionType,
          'result_category': resultCategory,
          'response_time_bucket': responseTimeBucket,
          'offline_state': 'online',
        },
      );
    } on OfflineModeException catch (e) {
      setState(() {
        _isCorrect = e.isCorrectLocal;
        _correctAnswer = e.correctAnswer;
        _explanation = e.explanation;
        _isChecked = true;
        _answeredQuestionIds.add(questionId);
        _questionCorrectness[questionId] = (questionType == 'speaking') ? true : e.isCorrectLocal;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Log question_answered event
      String responseTimeBucket = '0_5s';
      if (elapsed >= 30000) {
        responseTimeBucket = '30s_plus';
      } else if (elapsed >= 15000) {
        responseTimeBucket = '15_30s';
      } else if (elapsed >= 5000) {
        responseTimeBucket = '5_15s';
      }

      final resultCategory = questionType == 'speaking'
          ? 'completion_only'
          : (e.isCorrectLocal ? 'correct' : 'incorrect');

      ref.read(monitoringServiceProvider).logEvent(
        'question_answered',
        parameters: {
          'course_id': courseId,
          'lesson_id': widget.lessonId,
          'question_type': questionType,
          'result_category': resultCategory,
          'response_time_bucket': responseTimeBucket,
          'offline_state': 'offline',
        },
      );

      // Log offline_attempt_created event
      ref.read(monitoringServiceProvider).logEvent(
        'offline_attempt_created',
        parameters: {
          'course_id': courseId,
          'lesson_id': widget.lessonId,
        },
      );
    } catch (e) {
      if (mounted) {
        String errMsg = 'Lỗi gửi kết quả: $e';
        if (e is StaleContentException) {
          errMsg = 'Nội dung bài học đã được cập nhật. Vui lòng tải lại bài học để tiếp tục.';
        }
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        if (e is StaleContentException) {
          // Reset local state variables
          setState(() {
            _selectedOptionIndex = null;
            _questionCorrectness.clear();
            _answeredQuestionIds.clear();
          });

          // Invalidate providers
          ref.invalidate(lessonDetailProvider(widget.lessonId));
          ref.invalidate(courseHomeProvider);
          ref.invalidate(progressSummaryProvider(courseId));
          context.go('/home');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeAndExit(String courseId, List<QuestionModel> questions) async {
    final gradableQuestions = questions.where((q) => q.type != 'speaking').toList();

    final hasUnanswered = questions.any(
      (q) => !_answeredQuestionIds.contains(q.questionId),
    );

    final hasIncorrect = gradableQuestions.any(
      (q) => _questionCorrectness[q.questionId] != true,
    );

    if (hasUnanswered || hasIncorrect) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bài học chưa hoàn thành: Bạn cần trả lời đúng tất cả các câu hỏi để hoàn thành bài học này.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final monitoring = ref.read(monitoringServiceProvider);

    try {
      final repository = ref.read(contentRepositoryProvider);
      final result = await repository.completeLesson(courseId, widget.lessonId);

      await monitoring.logEvent(
        'lesson_completed',
        parameters: {
          'course_id': courseId,
          'lesson_id': widget.lessonId,
          'sync_state': 'online_synced',
        },
      );

      if (result == CompleteLessonResult.pendingOffline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có kết nối mạng. Bài làm đã được ghi nhận ngoại tuyến và sẽ đồng bộ khi có mạng lại.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        ref.invalidate(courseHomeProvider);
        ref.invalidate(progressSummaryProvider(courseId));
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error completing lesson: $e');
      await monitoring.logEvent(
        'lesson_completed',
        parameters: {
          'course_id': courseId,
          'lesson_id': widget.lessonId,
          'sync_state': 'offline_failed',
        },
      );

      if (mounted) {
        String errMsg = 'Không thể hoàn thành bài học. Vui lòng thử lại sau.';
        if (e is LessonIncompleteException) {
          errMsg = 'Bài học chưa hoàn thành: Bạn cần trả lời đúng tất cả các câu hỏi để hoàn thành bài học này.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
          ),
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

  void _nextQuestion(int totalQuestions) {
    setState(() {
      _currentIndex++;
      _selectedOptionIndex = null;
      _isChecked = false;
      _correctAnswer = '';
      _explanation = '';
      _startTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final courseId = ref.watch(selectedCourseIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện tập'),
      ),
      body: lessonAsync.when(
        loading: () => const LoadingView(message: 'Đang tải bài tập...'),
        error: (error, stack) => ErrorView(
          message: 'Không thể tải bài tập. Vui lòng kiểm tra kết nối.',
          onRetry: () => ref.invalidate(lessonDetailProvider(widget.lessonId)),
        ),
        data: (lessonData) {
          if (lessonData.questions.isEmpty) {
            return const Center(child: Text('Bài học này chưa có câu hỏi luyện tập nào.'));
          }

          final question = lessonData.questions[_currentIndex];
          final totalQuestions = lessonData.questions.length;
          final progress = (_currentIndex + (_isChecked ? 1.0 : 0.0)) / totalQuestions;

          if (question.type == 'speaking') {
            if (!_isChecked) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: _isSubmitting,
                                child: ListenAndRepeatCard(
                                  audioUrl: question.audioUrl ?? '',
                                  transcript: question.correctAnswer ?? '',
                                  onComplete: () {
                                    _submitAnswer(
                                      courseId,
                                      question.questionId,
                                      question.versionId ?? '${question.questionId}_v1',
                                      'SPOKEN_SELF_REVIEWED',
                                      question.type,
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (_isSubmitting)
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 80,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Hoàn thành luyện nói!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              question.correctAnswer ?? '',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bạn đã tự đánh giá phần luyện nói này.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_explanation.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          color: Colors.green.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Giải thích & Hướng dẫn:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _explanation,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (_currentIndex + 1 >= totalQuestions) {
                                  _completeAndExit(courseId, lessonData.questions);
                                } else {
                                  _nextQuestion(totalQuestions);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentIndex + 1 >= totalQuestions ? 'Hoàn thành bài học' : 'Tiếp tục',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 24),
                  
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        question.prompt,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: ListView.separated(
                      itemCount: question.options.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final option = question.options[index];
                        final isSelected = _selectedOptionIndex == index;
                        
                        Color cardBorderColor = Colors.transparent;
                        Color cardBgColor = theme.colorScheme.surface;
                        
                        if (isSelected) {
                          cardBorderColor = theme.colorScheme.primary;
                          cardBgColor = theme.colorScheme.primary.withOpacity(0.05);
                        }
                        
                        if (_isChecked) {
                          final isCorrectOption = option.optionText == _correctAnswer;
                          if (isCorrectOption) {
                            cardBorderColor = Colors.green;
                            cardBgColor = Colors.green.withOpacity(0.1);
                          } else if (isSelected) {
                            cardBorderColor = Colors.red;
                            cardBgColor = Colors.red.withOpacity(0.1);
                          }
                        }

                        return InkWell(
                          onTap: _isChecked || _isSubmitting ? null : () {
                            setState(() {
                              _selectedOptionIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              border: Border.all(
                                color: cardBorderColor != Colors.transparent 
                                    ? cardBorderColor 
                                    : theme.colorScheme.outline.withOpacity(0.2),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.optionText,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (_isChecked && option.optionText == _correctAnswer)
                                  const Icon(Icons.check_circle_rounded, color: Colors.green)
                                else if (_isChecked && isSelected && option.optionText != _correctAnswer)
                                  const Icon(Icons.cancel_rounded, color: Colors.red),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  if (_isChecked) ...[
                    Card(
                      elevation: 0,
                      color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCorrect ? 'Chính xác! Rất tốt.' : 'Chưa chính xác!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isCorrect ? Colors.green : Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            if (_explanation.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Giải thích: $_explanation',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  ElevatedButton(
                    onPressed: _selectedOptionIndex == null || _isSubmitting
                        ? null 
                        : () {
                            if (!_isChecked) {
                              final selectedAnswer = question.options[_selectedOptionIndex!].optionText;
                              _submitAnswer(
                                courseId,
                                question.questionId,
                                question.versionId ?? '${question.questionId}_v1',
                                selectedAnswer,
                                question.type,
                              );
                            } else {
                              if (_currentIndex + 1 >= totalQuestions) {
                                _completeAndExit(courseId, lessonData.questions);
                              } else {
                                _nextQuestion(totalQuestions);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChecked 
                          ? (_isCorrect ? Colors.green : theme.colorScheme.primary) 
                          : theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isChecked 
                                ? (_currentIndex + 1 >= totalQuestions ? 'Hoàn thành bài học' : 'Tiếp tục')
                                : 'Kiểm tra đáp án',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

