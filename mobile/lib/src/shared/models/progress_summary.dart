class ProgressSummaryModel {
  final int completedLessonsCount;
  final int totalLessonsCount;
  final double courseCompletionPercent;
  final int streak;
  final double accuracy;
  final int learnedWordsCount;
  final int dueReviewCount;

  ProgressSummaryModel({
    required this.completedLessonsCount,
    required this.totalLessonsCount,
    required this.courseCompletionPercent,
    required this.streak,
    required this.accuracy,
    required this.learnedWordsCount,
    required this.dueReviewCount,
  });

  factory ProgressSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProgressSummaryModel(
      completedLessonsCount: (json['completedLessonsCount'] as num?)?.toInt() ?? 0,
      totalLessonsCount: (json['totalLessonsCount'] as num?)?.toInt() ?? 0,
      courseCompletionPercent: (json['courseCompletionPercent'] as num?)?.toDouble() ?? 0.0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 100.0,
      learnedWordsCount: (json['learnedWordsCount'] as num?)?.toInt() ?? 0,
      dueReviewCount: (json['dueReviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedLessonsCount': completedLessonsCount,
      'totalLessonsCount': totalLessonsCount,
      'courseCompletionPercent': courseCompletionPercent,
      'streak': streak,
      'accuracy': accuracy,
      'learnedWordsCount': learnedWordsCount,
      'dueReviewCount': dueReviewCount,
    };
  }
}
