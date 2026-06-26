package com.esquilospeak.learning.client;

import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import java.util.List;

public interface ContentClient {
    QuestionDto getQuestion(String questionId);
    List<String> getCourseLessons(String courseId);
    List<String> getLessonQuestionIds(String courseId, String lessonId);
}
