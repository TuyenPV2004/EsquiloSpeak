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
import com.esquilospeak.learning.service.ReviewItemService;

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
    private ReviewItemService reviewItemService;

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
                    Optional<QuestionAttempt> existing = questionAttemptRepository.findByUserIdAndClientRequestId(userId, clientRequestId);
                    if (existing.isPresent()) {
                        results.add(new SyncResult(clientRequestId, "DUPLICATE", null, null));
                        continue;
                    }

                    // Kiểm tra questionVersionId của client
                    if (attemptReq.getQuestionVersionId() == null || attemptReq.getQuestionVersionId().isBlank()) {
                        results.add(new SyncResult(clientRequestId, "FAILED", "MISSING_QUESTION_VERSION", "questionVersionId is required to submit an attempt."));
                        continue;
                    }

                    // 2. Fetch Question details
                    AttemptController.QuestionDto question = contentClient.getQuestion(attemptReq.getQuestionId());
                    if (question == null) {
                        results.add(new SyncResult(clientRequestId, "FAILED", "QUESTION_NOT_FOUND", "Question not found in content-service."));
                        continue;
                    }

                    // Kiểm tra versionId của server
                    if (question.getVersionId() == null || question.getVersionId().isBlank()) {
                        results.add(new SyncResult(clientRequestId, "RETRYABLE_FAILED", "QUESTION_VERSION_MISSING", "Question version is missing in content-service."));
                        continue;
                    }

                    // 3. Audit question version bằng Objects.equals
                    if (!java.util.Objects.equals(attemptReq.getQuestionVersionId(), question.getVersionId())) {
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
                        reviewItemService.upsertReviewItemFromAttempt(
                                userId,
                                attemptReq.getCourseId(),
                                question,
                                isCorrect,
                                attemptReq.isUsedHint(),
                                attemptReq.getResponseTimeMs(),
                                answeredAt
                        );
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
