class CourseModel {
  final String courseId;
  final String title;
  final String sourceLanguage;
  final String targetLanguage;
  final String level;
  final DateTime? createdAt;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.level,
    this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      level: json['level'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'title': title,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'level': level,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
