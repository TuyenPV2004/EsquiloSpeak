class LessonInfoModel {
  final String lessonId;
  final String title;
  final String status;

  LessonInfoModel({
    required this.lessonId,
    required this.title,
    required this.status,
  });

  factory LessonInfoModel.fromJson(Map<String, dynamic> json) {
    return LessonInfoModel(
      lessonId: json['lessonId'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'title': title,
      'status': status,
    };
  }
}

class CourseHomeModel {
  final String courseId;
  final String? activeUnitId;
  final String? activeUnitTitle;
  final int progressPercent;
  final List<LessonInfoModel> lessons;
  final int dueReviewCount;

  CourseHomeModel({
    required this.courseId,
    this.activeUnitId,
    this.activeUnitTitle,
    required this.progressPercent,
    required this.lessons,
    required this.dueReviewCount,
  });

  factory CourseHomeModel.fromJson(Map<String, dynamic> json) {
    var lessonsList = json['lessons'] as List? ?? [];
    List<LessonInfoModel> parsedLessons = lessonsList
        .map((e) => LessonInfoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CourseHomeModel(
      courseId: json['courseId'] as String,
      activeUnitId: json['activeUnitId'] as String?,
      activeUnitTitle: json['activeUnitTitle'] as String?,
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      lessons: parsedLessons,
      dueReviewCount: (json['dueReviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'activeUnitId': activeUnitId,
      'activeUnitTitle': activeUnitTitle,
      'progressPercent': progressPercent,
      'lessons': lessons.map((e) => e.toJson()).toList(),
      'dueReviewCount': dueReviewCount,
    };
  }
}
