class AttemptResponseModel {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final bool reviewCreated;

  AttemptResponseModel({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.reviewCreated,
  });

  factory AttemptResponseModel.fromJson(Map<String, dynamic> json) {
    return AttemptResponseModel(
      isCorrect: json['isCorrect'] as bool? ?? false,
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      reviewCreated: json['reviewCreated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCorrect': isCorrect,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'reviewCreated': reviewCreated,
    };
  }
}
