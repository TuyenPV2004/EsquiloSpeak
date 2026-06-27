package com.esquilospeak.learning.service;

import com.esquilospeak.learning.api.AttemptController.AttemptRequest;
import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import com.esquilospeak.learning.client.ContentClient;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;

@Service
public class AttemptValidationService {
    private static final String SPOKEN_SELF_REVIEWED = "SPOKEN_SELF_REVIEWED";

    private final ContentClient contentClient;

    public AttemptValidationService(ContentClient contentClient) {
        this.contentClient = contentClient;
    }

    public ValidatedAttempt validateOnlineAttempt(String pathCourseId, AttemptRequest request) {
        validateCourseIdMatchesPath(pathCourseId, request);
        return validateAttemptContent(request);
    }

    public ValidatedAttempt validateSyncAttempt(AttemptRequest request) {
        return validateAttemptContent(request);
    }

    private void validateCourseIdMatchesPath(String pathCourseId, AttemptRequest request) {
        if (!Objects.equals(pathCourseId, request.getCourseId())) {
            throw badRequest("COURSE_ID_MISMATCH", "courseId in request body must match courseId in URL.");
        }
    }

    private ValidatedAttempt validateAttemptContent(AttemptRequest request) {
        validateContentOwnership(request);
        QuestionDto question = validateQuestionVersion(request);
        boolean isSpeaking = "speaking".equalsIgnoreCase(question.getType());
        boolean isCorrect = validateAttemptTypeAndAnswer(request, question, isSpeaking);
        return new ValidatedAttempt(question, isCorrect, isSpeaking);
    }

    private void validateContentOwnership(AttemptRequest request) {
        List<String> lessonQuestionIds = contentClient.getLessonQuestionIds(request.getCourseId(), request.getLessonId());
        if (lessonQuestionIds == null) {
            throw badRequest("LESSON_NOT_IN_COURSE", "Lesson does not belong to the requested course.");
        }
        if (!lessonQuestionIds.contains(request.getQuestionId())) {
            throw badRequest("QUESTION_NOT_IN_LESSON", "Question does not belong to the requested lesson.");
        }
    }

    private QuestionDto validateQuestionVersion(AttemptRequest request) {
        QuestionDto question = contentClient.getQuestion(request.getQuestionId());
        if (question == null) {
            throw badRequest("QUESTION_NOT_FOUND", "Question not found in content-service.");
        }
        if (question.getVersionId() == null || question.getVersionId().isBlank()) {
            throw new AttemptValidationException(
                    "QUESTION_VERSION_MISSING",
                    "Question version is missing in content-service.",
                    HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
        if (!Objects.equals(request.getQuestionVersionId(), question.getVersionId())) {
            throw badRequest("STALE_CONTENT", "The question version on the client is stale. Please refresh content.");
        }
        return question;
    }

    private boolean validateAttemptTypeAndAnswer(AttemptRequest request, QuestionDto question, boolean isSpeaking) {
        if (SPOKEN_SELF_REVIEWED.equals(request.getSelectedAnswer())) {
            if (!isSpeaking) {
                throw badRequest("INVALID_ATTEMPT_TYPE", "Self-reviewed answers are only allowed for speaking questions.");
            }
            return true;
        }

        if (isSpeaking) {
            throw badRequest("INVALID_ATTEMPT_TYPE", "Speaking questions must be answered with SPOKEN_SELF_REVIEWED.");
        }

        if (request.getSelectedAnswer() == null || request.getSelectedAnswer().isBlank()) {
            throw badRequest("INVALID_ATTEMPT_TYPE", "selectedAnswer is required for non-speaking questions.");
        }

        return question.getCorrectAnswer() != null &&
                request.getSelectedAnswer().trim().equalsIgnoreCase(question.getCorrectAnswer().trim());
    }

    private AttemptValidationException badRequest(String code, String message) {
        return new AttemptValidationException(code, message, HttpStatus.BAD_REQUEST);
    }

    public record ValidatedAttempt(QuestionDto question, boolean isCorrect, boolean isSpeaking) {}
}
