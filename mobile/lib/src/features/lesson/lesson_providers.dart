import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_providers.dart';
import '../../shared/models/question.dart';
import '../../shared/repositories/content_repository.dart';

final lessonDetailProvider = FutureProvider.family<LessonDetailResponseModel, String>((ref, lessonId) async {
  final courseId = ref.watch(selectedCourseIdProvider);
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getLessonDetail(courseId, lessonId);
});
