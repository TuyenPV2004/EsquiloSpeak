import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/shared/models/question.dart';

void main() {
  group('Speaking exercise business rules', () {
    test('Speaking questions identify correctly and use SPOKEN_SELF_REVIEWED answer', () {
      final questionJson = {
        'questionId': 'q_113',
        'lessonId': 'lesson_1_2',
        'prompt': 'Hello, how are you?',
        'type': 'speaking',
        'correctAnswer': 'SPOKEN_SELF_REVIEWED',
        'explanation': 'Đọc to câu tiếng Anh trên.',
        'versionId': 'q_113_v1',
        'options': []
      };

      final question = QuestionModel.fromJson(questionJson);
      expect(question.type, 'speaking');
      expect(question.correctAnswer, 'SPOKEN_SELF_REVIEWED');
    });
  });
}
