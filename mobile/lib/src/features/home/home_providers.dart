import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/course_home.dart';
import '../../shared/repositories/content_repository.dart';

final selectedCourseIdProvider = StateProvider<String>((ref) => 'en_for_vi');

final courseHomeProvider = FutureProvider<CourseHomeModel>((ref) async {
  final courseId = ref.watch(selectedCourseIdProvider);
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getCourseHome(courseId);
});
