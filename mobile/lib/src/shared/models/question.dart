class QuestionOptionModel {
  final int? optionId;
  final String optionText;

  QuestionOptionModel({
    this.optionId,
    required this.optionText,
  });

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      optionId: json['optionId'] as int?,
      optionText: json['optionText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'optionText': optionText,
    };
  }
}

class QuestionModel {
  final String questionId;
  final String lessonId;
  final String prompt;
  final String type;
  final String? audioUrl;
  final String? correctAnswer;
  final String? explanation;
  final String? versionId;
  final List<QuestionOptionModel> options;

  QuestionModel({
    required this.questionId,
    required this.lessonId,
    required this.prompt,
    required this.type,
    this.audioUrl,
    this.correctAnswer,
    this.explanation,
    this.versionId,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var optionsList = json['options'] as List? ?? [];
    List<QuestionOptionModel> parsedOptions = optionsList
        .map((e) => QuestionOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return QuestionModel(
      questionId: json['questionId'] as String,
      lessonId: json['lessonId'] as String,
      prompt: json['prompt'] as String,
      type: json['type'] as String,
      audioUrl: json['audioUrl'] as String?,
      correctAnswer: json['correctAnswer'] as String?,
      explanation: json['explanation'] as String?,
      versionId: json['versionId'] as String?,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'lessonId': lessonId,
      'prompt': prompt,
      'type': type,
      'audioUrl': audioUrl,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'versionId': versionId,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class LessonDetailResponseModel {
  final String lessonId;
  final String? lessonVersionId;
  final String title;
  final List<QuestionModel> questions;

  LessonDetailResponseModel({
    required this.lessonId,
    this.lessonVersionId,
    required this.title,
    required this.questions,
  });

  factory LessonDetailResponseModel.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List? ?? [];
    List<QuestionModel> parsedQuestions = questionsList
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return LessonDetailResponseModel(
      lessonId: json['lessonId'] as String,
      lessonVersionId: json['lessonVersionId'] as String?,
      title: json['title'] as String,
      questions: parsedQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonVersionId': lessonVersionId,
      'title': title,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}
