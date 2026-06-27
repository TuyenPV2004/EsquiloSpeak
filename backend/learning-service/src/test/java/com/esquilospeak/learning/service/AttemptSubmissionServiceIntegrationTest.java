package com.esquilospeak.learning.service;

import com.esquilospeak.learning.BaseIntegrationTest;
import com.esquilospeak.learning.api.AttemptController;
import com.esquilospeak.learning.api.SyncController;
import com.esquilospeak.learning.client.ContentClient;
import com.esquilospeak.learning.domain.AttemptIdempotencyRecord;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.infrastructure.AttemptIdempotencyRecordRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

public class AttemptSubmissionServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private AttemptSubmissionService attemptSubmissionService;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @Autowired
    private AttemptIdempotencyRecordRepository idempotencyRecordRepository;

    @MockBean
    private ContentClient contentClient;

    @Test
    public void submitOnlineAttempt_RetrySamePayload_ReturnsSnapshotWithoutDuplicateSideEffects() {
        String userId = "user_idem_" + UUID.randomUUID();
        String clientRequestId = "req_" + UUID.randomUUID();
        AttemptController.AttemptRequest request = attempt(clientRequestId, "q_idem_1", "q_idem_1_v1", "Correct");

        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_idem_1"));
        when(contentClient.getQuestion("q_idem_1")).thenReturn(question("q_idem_1", "q_idem_1_v1", "Correct"));

        AttemptSubmissionService.AttemptSubmissionResult first =
                attemptSubmissionService.submitOnlineAttempt(userId, "course_1", request);
        AttemptSubmissionService.AttemptSubmissionResult retry =
                attemptSubmissionService.submitOnlineAttempt(userId, "course_1", request);

        assertTrue(first.isSuccess());
        assertFalse(first.isDuplicate());
        assertTrue(retry.isSuccess());
        assertTrue(retry.isDuplicate());
        assertEquals("Correct", retry.getResponse().getCorrectAnswer());
        assertEquals("Explanation", retry.getResponse().getExplanation());

        List<QuestionAttempt> attempts = questionAttemptRepository.findByUserId(userId);
        assertEquals(1, attempts.size());

        Optional<ReviewItem> reviewItem = reviewItemRepository
                .findByUserIdAndCourseIdAndLearningItemIdAndType(userId, "course_1", "q_idem_1", "vocabulary");
        assertTrue(reviewItem.isPresent());

        AttemptIdempotencyRecord record = idempotencyRecordRepository
                .findByUserIdAndClientRequestId(userId, clientRequestId)
                .orElseThrow();
        assertEquals("SUCCEEDED", record.getStatus());
        assertNotNull(record.getSnapshotJson());
    }

    @Test
    public void submitOnlineAttempt_RetrySameKeyDifferentPayload_ReturnsConflict() {
        String userId = "user_conflict_" + UUID.randomUUID();
        String clientRequestId = "req_" + UUID.randomUUID();
        AttemptController.AttemptRequest firstRequest = attempt(clientRequestId, "q_conflict", "q_conflict_v1", "Correct");
        AttemptController.AttemptRequest conflictingRequest = attempt(clientRequestId, "q_conflict", "q_conflict_v1", "Wrong");

        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_conflict"));
        when(contentClient.getQuestion("q_conflict")).thenReturn(question("q_conflict", "q_conflict_v1", "Correct"));

        AttemptSubmissionService.AttemptSubmissionResult first =
                attemptSubmissionService.submitOnlineAttempt(userId, "course_1", firstRequest);
        AttemptSubmissionService.AttemptSubmissionResult conflict =
                attemptSubmissionService.submitOnlineAttempt(userId, "course_1", conflictingRequest);

        assertTrue(first.isSuccess());
        assertFalse(conflict.isSuccess());
        assertEquals("IDEMPOTENCY_CONFLICT", conflict.getErrorCode());
        assertEquals(1, questionAttemptRepository.findByUserId(userId).size());
    }

    @Test
    public void syncAttempt_StaleContentPersistsPermanentFailureForRetry() {
        String userId = "user_stale_" + UUID.randomUUID();
        String clientRequestId = "req_" + UUID.randomUUID();
        AttemptController.AttemptRequest request = attempt(clientRequestId, "q_stale", "q_stale_old", "Correct");

        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_stale"));
        when(contentClient.getQuestion("q_stale")).thenReturn(question("q_stale", "q_stale_new", "Correct"));

        SyncController.SyncResult first = attemptSubmissionService.syncAttempt(userId, request);
        SyncController.SyncResult retry = attemptSubmissionService.syncAttempt(userId, request);

        assertEquals("FAILED", first.getStatus());
        assertEquals("STALE_CONTENT", first.getErrorCode());
        assertEquals("FAILED", retry.getStatus());
        assertEquals("STALE_CONTENT", retry.getErrorCode());
        assertTrue(questionAttemptRepository.findByUserId(userId).isEmpty());

        AttemptIdempotencyRecord record = idempotencyRecordRepository
                .findByUserIdAndClientRequestId(userId, clientRequestId)
                .orElseThrow();
        assertEquals("FAILED_PERMANENT", record.getStatus());
        assertEquals("STALE_CONTENT", record.getErrorCode());
    }

    @Test
    public void syncAttempt_QuestionOutsideLesson_ReturnsFailedWithoutSideEffects() {
        String userId = "user_scope_" + UUID.randomUUID();
        String clientRequestId = "req_" + UUID.randomUUID();
        AttemptController.AttemptRequest request = attempt(clientRequestId, "q_outside", "q_outside_v1", "Correct");

        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_inside"));

        SyncController.SyncResult result = attemptSubmissionService.syncAttempt(userId, request);
        SyncController.SyncResult retry = attemptSubmissionService.syncAttempt(userId, request);

        assertEquals("FAILED", result.getStatus());
        assertEquals("QUESTION_NOT_IN_LESSON", result.getErrorCode());
        assertEquals("FAILED", retry.getStatus());
        assertEquals("QUESTION_NOT_IN_LESSON", retry.getErrorCode());
        assertTrue(questionAttemptRepository.findByUserId(userId).isEmpty());
        assertTrue(reviewItemRepository.findAll().stream()
                .noneMatch(item -> userId.equals(item.getUserId())));

        AttemptIdempotencyRecord record = idempotencyRecordRepository
                .findByUserIdAndClientRequestId(userId, clientRequestId)
                .orElseThrow();
        assertEquals("FAILED_PERMANENT", record.getStatus());
        assertEquals("QUESTION_NOT_IN_LESSON", record.getErrorCode());
    }

    @Test
    public void syncAttempt_ContentQuestionVersionMissing_ReturnsRetryableWithoutTerminalRecord() {
        String userId = "user_missing_version_" + UUID.randomUUID();
        String clientRequestId = "req_" + UUID.randomUUID();
        AttemptController.AttemptRequest request = attempt(clientRequestId, "q_missing_version", "q_missing_version_v1", "Correct");

        AttemptController.QuestionDto question = question("q_missing_version", "", "Correct");
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(List.of("q_missing_version"));
        when(contentClient.getQuestion("q_missing_version")).thenReturn(question);

        SyncController.SyncResult result = attemptSubmissionService.syncAttempt(userId, request);
        SyncController.SyncResult retry = attemptSubmissionService.syncAttempt(userId, request);

        assertEquals("RETRYABLE_FAILED", result.getStatus());
        assertEquals("QUESTION_VERSION_MISSING", result.getErrorCode());
        assertEquals("RETRYABLE_FAILED", retry.getStatus());
        assertEquals("QUESTION_VERSION_MISSING", retry.getErrorCode());
        assertTrue(questionAttemptRepository.findByUserId(userId).isEmpty());
        assertTrue(idempotencyRecordRepository
                .findByUserIdAndClientRequestId(userId, clientRequestId)
                .isEmpty());
    }

    @Test
    public void syncAttempt_LegacyExistingAttemptWithoutRecord_ReturnsDuplicate() {
        String userId = "user_legacy_" + UUID.randomUUID();
        String clientRequestId = "req_" + UUID.randomUUID();
        AttemptController.AttemptRequest request = attempt(clientRequestId, "q_legacy", "q_legacy_v1", "Correct");
        QuestionAttempt existing = new QuestionAttempt(
                "att_" + UUID.randomUUID(),
                clientRequestId,
                userId,
                "course_1",
                "lesson_1",
                "q_legacy",
                "q_legacy_v1",
                "Correct",
                true,
                1500,
                request.getAnsweredAt()
        );
        questionAttemptRepository.saveAndFlush(existing);

        SyncController.SyncResult result = attemptSubmissionService.syncAttempt(userId, request);

        assertEquals("DUPLICATE", result.getStatus());
        assertEquals(1, questionAttemptRepository.findByUserId(userId).size());
        AttemptIdempotencyRecord record = idempotencyRecordRepository
                .findByUserIdAndClientRequestId(userId, clientRequestId)
                .orElseThrow();
        assertEquals("SUCCEEDED", record.getStatus());
    }

    private AttemptController.AttemptRequest attempt(
            String clientRequestId,
            String questionId,
            String questionVersionId,
            String selectedAnswer) {
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId(clientRequestId);
        attempt.setDeviceId("device_123");
        attempt.setCourseId("course_1");
        attempt.setSourceLanguage("vi");
        attempt.setTargetLanguage("en");
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
