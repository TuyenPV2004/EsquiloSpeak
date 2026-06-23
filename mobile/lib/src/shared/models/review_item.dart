class ReviewItemModel {
  final String reviewItemId;
  final String userId;
  final String courseId;
  final String concept;
  final String type;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final DateTime nextReviewAt;
  final String correctAnswer;
  final String explanation;

  ReviewItemModel({
    required this.reviewItemId,
    required this.userId,
    required this.courseId,
    required this.concept,
    required this.type,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    required this.nextReviewAt,
    required this.correctAnswer,
    required this.explanation,
  });

  factory ReviewItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewItemModel(
      reviewItemId: json['reviewItemId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      concept: json['concept'] as String? ?? '',
      type: json['type'] as String? ?? '',
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
      repetitionCount: (json['repetitionCount'] as num?)?.toInt() ?? 0,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'] as String)
          : DateTime.now(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewItemId': reviewItemId,
      'userId': userId,
      'courseId': courseId,
      'concept': concept,
      'type': type,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'repetitionCount': repetitionCount,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}
