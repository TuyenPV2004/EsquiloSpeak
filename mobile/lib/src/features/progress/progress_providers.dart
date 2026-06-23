import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/repositories/content_repository.dart';
import '../../shared/models/progress_summary.dart';

final progressSummaryProvider = FutureProvider.family<ProgressSummaryModel, String>((ref, courseId) async {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.getProgressSummary(courseId);
});
