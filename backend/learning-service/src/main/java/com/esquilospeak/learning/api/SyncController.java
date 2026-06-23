package com.esquilospeak.learning.api;

import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.esquilospeak.learning.client.ContentClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.esquilospeak.learning.util.HmacUtil;
import java.time.Clock;
import com.esquilospeak.learning.service.Sm2Scheduler;

import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/v1")
public class SyncController {

    private static final Logger log = LoggerFactory.getLogger(SyncController.class);

    @Value("${analytics.hash-secret}")
    private String hashSecret;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @Autowired
    private ContentClient contentClient;

    @Autowired
    private Clock clock;

    @PostMapping("/sync/attempts")
    public ResponseEntity<SyncResponse> syncAttempts(
            @RequestAttribute("userId") String userId,
            @RequestBody SyncRequest request) {

        List<SyncResult> results = new ArrayList<>();
        int syncedCount = 0;

        if (request.getAttempts() != null) {
            for (AttemptController.AttemptRequest attemptReq : request.getAttempts()) {
                String clientRequestId = attemptReq.getClientRequestId();
                try {
                    // 1. Idempotency Check (Duplicate check)
                    Optional<QuestionAttempt> existing = questionAttemptRepository.findByClientRequestId(clientRequestId);
                    if (existing.isPresent()) {
                        results.add(new SyncResult(clientRequestId, "DUPLICATE", null, null));
                        continue;
                    }

                    // 2. Fetch Question details
                    AttemptController.QuestionDto question = contentClient.getQuestion(attemptReq.getQuestionId());
                    if (question == null) {
                        results.add(new SyncResult(clientRequestId, "FAILED", "QUESTION_NOT_FOUND", "Question not found in content-service"));
                        continue;
                    }

                    // 3. Audit question version
                    if (attemptReq.getQuestionVersionId() != null && question.getVersionId() != null 
                            && !attemptReq.getQuestionVersionId().equalsIgnoreCase(question.getVersionId())) {
                        results.add(new SyncResult(clientRequestId, "FAILED", "STALE_CONTENT", "The question version on the client is stale. Please refresh content."));
                        continue;
                    }

                    // 4. Validate speaking self-review attempt
                    boolean isCorrect;
                    boolean isSpeaking = "speaking".equalsIgnoreCase(question.getType());

                    if ("SPOKEN_SELF_REVIEWED".equals(attemptReq.getSelectedAnswer())) {
                        if (!isSpeaking) {
                            results.add(new SyncResult(clientRequestId, "FAILED", "INVALID_ATTEMPT_TYPE", "Self-reviewed answers are only allowed for speaking questions."));
                            continue;
                        }
                        isCorrect = true;
                    } else {
                        if (isSpeaking) {
                            results.add(new SyncResult(clientRequestId, "FAILED", "INVALID_ATTEMPT_TYPE", "Speaking questions must be answered with SPOKEN_SELF_REVIEWED."));
                            continue;
                        }
                        isCorrect = attemptReq.getSelectedAnswer() != null &&
                                attemptReq.getSelectedAnswer().trim().equalsIgnoreCase(question.getCorrectAnswer().trim());
                    }

                    // 5. Save attempt
                    String attemptId = "att_" + UUID.randomUUID().toString().replace("-", "");
                    LocalDateTime answeredAt = attemptReq.getAnsweredAt() != null ? attemptReq.getAnsweredAt() : LocalDateTime.now(clock);
                    
                    QuestionAttempt attempt = new QuestionAttempt(
                            attemptId,
                            clientRequestId,
                            userId,
                            attemptReq.getCourseId(),
                            attemptReq.getLessonId(),
                            attemptReq.getQuestionId(),
                            attemptReq.getQuestionVersionId(),
                            attemptReq.getSelectedAnswer(),
                            isCorrect,
                            attemptReq.getResponseTimeMs(),
                            answeredAt
                    );

                    try {
                        questionAttemptRepository.save(attempt);
                    } catch (org.springframework.dao.DataIntegrityViolationException dive) {
                        results.add(new SyncResult(clientRequestId, "DUPLICATE", null, null));
                        continue;
                    }

                    // 6. SM-2 Scheduling
                    if (!isSpeaking) {
                        scheduleReviewItem(userId, attemptReq.getCourseId(), question, isCorrect, attemptReq.isUsedHint(), attemptReq.getResponseTimeMs());
                    }

                    results.add(new SyncResult(clientRequestId, "SYNCED", null, null));
                    syncedCount++;

                } catch (Exception e) {
                    results.add(new SyncResult(clientRequestId, "FAILED", "UNKNOWN_ERROR", e.getMessage()));
                }
            }
        }

        String userHash = HmacUtil.hashUserId(userId, hashSecret);
        long successCount = results.stream().filter(r -> "SYNCED".equals(r.getStatus()) || "DUPLICATE".equals(r.getStatus())).count();
        long failedPermanentCount = results.size() - successCount;

        log.info("{\"type\":\"analytics\",\"eventName\":\"sync_attempts\",\"userHash\":\"{}\",\"batchSize\":{},\"successCount\":{},\"failedPermanentCount\":{}}",
                userHash, results.size(), successCount, failedPermanentCount);

        return ResponseEntity.ok(new SyncResponse(true, results, syncedCount));
    }



    private void scheduleReviewItem(String userId, String courseId, AttemptController.QuestionDto question, 
                                    boolean isCorrect, boolean usedHint, int responseTimeMs) {
        String concept = question.getPrompt();
        String questionType = "vocabulary";

        Optional<ReviewItem> existingReviewOpt = reviewItemRepository.findByUserIdAndCourseIdAndConcept(userId, courseId, concept);

        // Map performance to quality q (0-5)
        int q;
        if (!isCorrect) {
            q = 1; // again
        } else if (usedHint || responseTimeMs > 8000) {
            q = 3; // hard
        } else if (responseTimeMs < 3000) {
            q = 5; // easy
        } else {
            q = 4; // good
        }

        ReviewItem reviewItem;
        if (existingReviewOpt.isPresent()) {
            reviewItem = existingReviewOpt.get();
            Sm2Scheduler.calculateNextReview(reviewItem, q, clock);
        } else {
            String reviewItemId = "rev_" + UUID.randomUUID().toString().replace("-", "");
            reviewItem = new ReviewItem(
                    reviewItemId,
                    userId,
                    courseId,
                    concept,
                    questionType,
                    LocalDateTime.now(clock)
            );
            Sm2Scheduler.initializeReviewItem(reviewItem, q, clock);
        }

        reviewItem.setCorrectAnswer(question.getCorrectAnswer());
        reviewItem.setExplanation(question.getExplanation());
        reviewItemRepository.save(reviewItem);
    }

    // Request/Response DTO classes
    public static class SyncRequest {
        private List<AttemptController.AttemptRequest> attempts;

        public List<AttemptController.AttemptRequest> getAttempts() { return attempts; }
        public void setAttempts(List<AttemptController.AttemptRequest> attempts) { this.attempts = attempts; }
    }

    public static class SyncResponse {
        private boolean success;
        private List<SyncResult> results;
        private int syncedCount;

        public SyncResponse(boolean success, List<SyncResult> results, int syncedCount) {
            this.success = success;
            this.results = results;
            this.syncedCount = syncedCount;
        }

        public boolean isSuccess() { return success; }
        public List<SyncResult> getResults() { return results; }
        public int getSyncedCount() { return syncedCount; }
    }

    public static class SyncResult {
        private String clientRequestId;
        private String status; // SYNCED, DUPLICATE, FAILED
        private String errorCode;
        private String message;

        public SyncResult(String clientRequestId, String status, String errorCode, String message) {
            this.clientRequestId = clientRequestId;
            this.status = status;
            this.errorCode = errorCode;
            this.message = message;
        }

        public String getClientRequestId() { return clientRequestId; }
        public String getStatus() { return status; }
        public String getErrorCode() { return errorCode; }
        public String getMessage() { return message; }
    }
}
