package com.esquilospeak.learning.service;

import com.esquilospeak.learning.api.AttemptController;
import com.esquilospeak.learning.client.ContentClient;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class AttemptValidationServiceTest {

    @Mock
    private ContentClient contentClient;

    @InjectMocks
    private AttemptValidationService attemptValidationService;

    @Test
    public void validateSyncAttempt_WhenQuestionIsOutsideLesson_ReturnsQuestionNotInLesson() {
        AttemptController.AttemptRequest request = attempt("q_outside", "q_outside_v1", "Correct");
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_inside"));

        AttemptValidationException ex = assertThrows(AttemptValidationException.class,
                () -> attemptValidationService.validateSyncAttempt(request));

        assertEquals("QUESTION_NOT_IN_LESSON", ex.getCode());
        assertEquals(HttpStatus.BAD_REQUEST, ex.getStatus());
    }

    @Test
    public void validateSyncAttempt_WhenQuestionVersionIsStale_ReturnsStaleContent() {
        AttemptController.AttemptRequest request = attempt("q_1", "q_1_old", "Correct");
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_1"));
        when(contentClient.getQuestion("q_1")).thenReturn(question("q_1", "q_1_new", "Correct"));

        AttemptValidationException ex = assertThrows(AttemptValidationException.class,
                () -> attemptValidationService.validateSyncAttempt(request));

        assertEquals("STALE_CONTENT", ex.getCode());
        assertEquals(HttpStatus.BAD_REQUEST, ex.getStatus());
    }

    @Test
    public void validateSyncAttempt_WhenContentVersionMissing_ReturnsRetryableServerErrorCode() {
        AttemptController.AttemptRequest request = attempt("q_1", "q_1_v1", "Correct");
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_1"));
        when(contentClient.getQuestion("q_1")).thenReturn(question("q_1", "", "Correct"));

        AttemptValidationException ex = assertThrows(AttemptValidationException.class,
                () -> attemptValidationService.validateSyncAttempt(request));

        assertEquals("QUESTION_VERSION_MISSING", ex.getCode());
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, ex.getStatus());
    }

    @Test
    public void validateSyncAttempt_WhenPayloadMatchesContent_ReturnsValidatedAttempt() {
        AttemptController.AttemptRequest request = attempt("q_1", "q_1_v1", "Correct");
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_1"));
        when(contentClient.getQuestion("q_1")).thenReturn(question("q_1", "q_1_v1", "Correct"));

        AttemptValidationService.ValidatedAttempt result = attemptValidationService.validateSyncAttempt(request);

        assertEquals("q_1", result.question().getQuestionId());
        assertEquals(true, result.isCorrect());
        assertEquals(false, result.isSpeaking());
    }

    private AttemptController.AttemptRequest attempt(String questionId, String questionVersionId, String selectedAnswer) {
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_1");
        attempt.setDeviceId("device_123");
        attempt.setCourseId("course_1");
        attempt.setLessonId("lesson_1");
        attempt.setLessonVersionId("lesson_1_v1");
        attempt.setQuestionId(questionId);
        attempt.setQuestionVersionId(questionVersionId);
        attempt.setSelectedAnswer(selectedAnswer);
        attempt.setResponseTimeMs(1500);
        attempt.setAnsweredAt(LocalDateTime.parse("2026-06-23T10:00:00"));
        return attempt;
    }

    private AttemptController.QuestionDto question(String questionId, String versionId, String correctAnswer) {
        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId(questionId);
        question.setCorrectAnswer(correctAnswer);
        question.setExplanation("Explanation");
        question.setPrompt("Prompt");
        question.setType("multiple_choice");
        question.setVersionId(versionId);
        return question;
    }
}
