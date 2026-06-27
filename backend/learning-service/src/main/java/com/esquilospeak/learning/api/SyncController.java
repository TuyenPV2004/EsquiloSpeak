package com.esquilospeak.learning.api;

import com.esquilospeak.learning.service.AttemptSubmissionOperations;
import com.esquilospeak.learning.util.HmacUtil;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Valid;
import jakarta.validation.Validator;
import jakarta.validation.constraints.NotEmpty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/v1")
public class SyncController {

    private static final Logger log = LoggerFactory.getLogger(SyncController.class);

    @Value("${analytics.hash-secret}")
    private String hashSecret;

    @Autowired
    private AttemptSubmissionOperations attemptSubmissionService;

    @Autowired
    private Validator validator;

    @PostMapping("/sync/attempts")
    public ResponseEntity<SyncResponse> syncAttempts(
            @RequestAttribute("userId") String userId,
            @Valid @RequestBody SyncRequest request) {

        List<SyncResult> results = new ArrayList<>();
        int syncedCount = 0;

        for (AttemptController.AttemptRequest attemptReq : request.getAttempts()) {
            String clientRequestId = attemptReq != null ? attemptReq.getClientRequestId() : null;
            try {
                if (attemptReq == null) {
                    results.add(new SyncResult(null, "FAILED", "INVALID_ATTEMPT_REQUEST", "Attempt request is missing required fields."));
                    continue;
                }

                Set<ConstraintViolation<AttemptController.AttemptRequest>> violations = validator.validate(attemptReq);
                if (!violations.isEmpty()) {
                    results.add(new SyncResult(clientRequestId, "FAILED", "INVALID_ATTEMPT_REQUEST", "Attempt request is missing required fields."));
                    continue;
                }

                SyncResult result = attemptSubmissionService.syncAttempt(userId, attemptReq);
                results.add(result);
                if ("SYNCED".equals(result.getStatus())) {
                    syncedCount++;
                }
            } catch (Exception e) {
                results.add(new SyncResult(clientRequestId, "RETRYABLE_FAILED", "UNKNOWN_ERROR", e.getMessage()));
            }
        }

        String userHash = HmacUtil.hashUserId(userId, hashSecret);
        long successCount = results.stream().filter(r -> "SYNCED".equals(r.getStatus()) || "DUPLICATE".equals(r.getStatus())).count();
        long failedPermanentCount = results.size() - successCount;

        log.info("{\"type\":\"analytics\",\"eventName\":\"sync_attempts\",\"userHash\":\"{}\",\"batchSize\":{},\"successCount\":{},\"failedPermanentCount\":{}}",
                userHash, results.size(), successCount, failedPermanentCount);

        return ResponseEntity.ok(new SyncResponse(true, results, syncedCount));
    }

    public static class SyncRequest {
        @NotEmpty
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
        private String status;
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
