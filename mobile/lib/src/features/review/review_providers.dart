import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/repositories/content_repository.dart';
import '../../shared/models/review_item.dart';

final dueReviewsProvider = FutureProvider.family<List<ReviewItemModel>, String>((ref, courseId) async {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.getDueReviews(courseId);
});
