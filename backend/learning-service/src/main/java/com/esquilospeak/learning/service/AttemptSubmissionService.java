package com.esquilospeak.learning.service;

import com.esquilospeak.learning.api.AttemptController.AttemptRequest;
import com.esquilospeak.learning.api.AttemptController.AttemptResponse;
import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import com.esquilospeak.learning.api.SyncController.SyncResult;
import com.esquilospeak.learning.domain.AttemptIdempotencyRecord;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.infrastructure.AttemptIdempotencyRecordRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

@Service
public class AttemptSubmissionService implements AttemptSubmissionOperations {
    private static final String STATUS_PROCESSING = "PROCESSING";
    private static final String STATUS_SUCCEEDED = "SUCCEEDED";
    private static final String STATUS_FAILED_PERMANENT = "FAILED_PERMANENT";
    private static final String IDEMPOTENCY_CONFLICT = "IDEMPOTENCY_CONFLICT";
    private static final String RETRYABLE_FAILED = "RETRYABLE_FAILED";
    private static final String QUESTION_VERSION_MISSING = "QUESTION_VERSION_MISSING";

    private final AttemptIdempotencyRecordRepository idempotencyRepository;
    private final QuestionAttemptRepository questionAttemptRepository;
    private final ReviewItemService reviewItemService;
    private final AttemptValidationService attemptValidationService;
    private final EntityManager entityManager;
    private final ObjectMapper objectMapper;
    private final ObjectMapper canonicalObjectMapper;

    public AttemptSubmissionService(
            AttemptIdempotencyRecordRepository idempotencyRepository,
            QuestionAttemptRepository questionAttemptRepository,
            ReviewItemService reviewItemService,
            AttemptValidationService attemptValidationService,
            EntityManager entityManager,
            ObjectMapper objectMapper) {
        this.idempotencyRepository = idempotencyRepository;
        this.questionAttemptRepository = questionAttemptRepository;
        this.reviewItemService = reviewItemService;
        this.attemptValidationService = attemptValidationService;
        this.entityManager = entityManager;
        this.objectMapper = objectMapper;
        this.canonicalObjectMapper = objectMapper.copy()
                .configure(MapperFeature.SORT_PROPERTIES_ALPHABETICALLY, true)
                .configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);
    }

    @Transactional(propagation = Propagation.REQUIRED)
    @Override
    public AttemptSubmissionResult submitOnlineAttempt(String userId, String pathCourseId, AttemptRequest request) {
        if (!Objects.equals(pathCourseId, request.getCourseId())) {
            return AttemptSubmissionResult.failed(
                    "COURSE_ID_MISMATCH",
                    "courseId in request body must match courseId in URL.",
                    HttpStatus.BAD_REQUEST,
                    false
            );
        }
        return processAttempt(userId, pathCourseId, request, true);
    }

    @Transactional(propagation = Propagation.REQUIRED)
    @Override
    public SyncResult syncAttempt(String userId, AttemptRequest request) {
        AttemptSubmissionResult result = processAttempt(userId, request.getCourseId(), request, false);
        if (result.isSuccess()) {
            return new SyncResult(
                    request.getClientRequestId(),
                    result.isDuplicate() ? "DUPLICATE" : "SYNCED",
                    null,
                    null
            );
        }
        return new SyncResult(
                request.getClientRequestId(),
                result.isRetryable() ? RETRYABLE_FAILED : "FAILED",
                result.getErrorCode(),
                result.getMessage()
        );
    }

    private AttemptSubmissionResult processAttempt(
            String userId,
            String effectiveCourseId,
            AttemptRequest request,
            boolean onlineSubmit) {
        String requestHash = hashRequest(effectiveCourseId, request);
        Optional<String> insertedRecordId = tryInsertProcessingRecord(userId, request.getClientRequestId(), requestHash);

        if (insertedRecordId.isEmpty()) {
            AttemptIdempotencyRecord existing = idempotencyRepository
                    .findByUserIdAndClientRequestIdForUpdate(userId, request.getClientRequestId())
                    .orElseThrow(() -> new IllegalStateException("Idempotency record disappeared after conflict."));
            return resultFromExistingRecord(existing, requestHash, onlineSubmit);
        }

        AttemptIdempotencyRecord record = idempotencyRepository
                .findById(insertedRecordId.get())
                .orElseThrow(() -> new IllegalStateException("Inserted idempotency record cannot be found."));

        Optional<QuestionAttempt> legacyAttempt = questionAttemptRepository
                .findByUserIdAndClientRequestId(userId, request.getClientRequestId());
        if (legacyAttempt.isPresent()) {
            AttemptSubmissionResult legacyResult = handleLegacyAttempt(record, legacyAttempt.get(), request);
            idempotencyRepository.saveAndFlush(record);
            return legacyResult;
        }

        AttemptValidationService.ValidatedAttempt validatedAttempt;
        try {
            validatedAttempt = onlineSubmit
                    ? attemptValidationService.validateOnlineAttempt(effectiveCourseId, request)
                    : attemptValidationService.validateSyncAttempt(request);
        } catch (AttemptValidationException e) {
            if (QUESTION_VERSION_MISSING.equals(e.getCode())) {
                idempotencyRepository.delete(record);
                idempotencyRepository.flush();
                return AttemptSubmissionResult.failed(e.getCode(), e.getMessage(), e.getStatus(), true);
            }

            AttemptSnapshot snapshot = AttemptSnapshot.permanentFailure(
                    request.getAnsweredAt(),
                    e.getCode(),
                    e.getMessage()
            );
            markTerminal(record, STATUS_FAILED_PERMANENT, snapshot, null, e.getCode(), e.getMessage());
            return AttemptSubmissionResult.failed(e.getCode(), e.getMessage(), e.getStatus(), false);
        }

        QuestionDto question = validatedAttempt.question();
        String attemptId = "att_" + UUID.randomUUID().toString().replace("-", "");
        QuestionAttempt attempt = new QuestionAttempt(
                attemptId,
                request.getClientRequestId(),
                userId,
                effectiveCourseId,
                request.getLessonId(),
                request.getQuestionId(),
                request.getQuestionVersionId(),
                request.getSelectedAnswer(),
                validatedAttempt.isCorrect(),
                request.getResponseTimeMs(),
                request.getAnsweredAt()
        );

        try {
            questionAttemptRepository.saveAndFlush(attempt);
        } catch (DataIntegrityViolationException ex) {
            QuestionAttempt existingAttempt = questionAttemptRepository
                    .findByUserIdAndClientRequestId(userId, request.getClientRequestId())
                    .orElseThrow(() -> ex);
            AttemptSubmissionResult legacyResult = handleLegacyAttempt(record, existingAttempt, request);
            idempotencyRepository.saveAndFlush(record);
            return legacyResult;
        }

        boolean reviewCreatedOrUpdated = false;
        if (!validatedAttempt.isSpeaking()) {
            reviewItemService.upsertReviewItemFromAttempt(
                    userId,
                    effectiveCourseId,
                    question,
                    validatedAttempt.isCorrect(),
                    request.isUsedHint(),
                    request.getResponseTimeMs(),
                    request.getAnsweredAt()
            );
            reviewCreatedOrUpdated = true;
        }

        AttemptSnapshot snapshot = AttemptSnapshot.success(
                attemptId,
                validatedAttempt.isCorrect(),
                question.getCorrectAnswer(),
                question.getExplanation(),
                reviewCreatedOrUpdated,
                request.getAnsweredAt()
        );
        markTerminal(record, STATUS_SUCCEEDED, snapshot, attemptId, null, null);
        return AttemptSubmissionResult.success(snapshot.toAttemptResponse(), false);
    }

    private AttemptSubmissionResult resultFromExistingRecord(
            AttemptIdempotencyRecord record,
            String requestHash,
            boolean onlineSubmit) {
        if (!Objects.equals(record.getRequestHash(), requestHash)) {
            return AttemptSubmissionResult.failed(
                    IDEMPOTENCY_CONFLICT,
                    "clientRequestId was already used for a different attempt payload.",
                    HttpStatus.CONFLICT,
                    false
            );
        }

        AttemptSnapshot snapshot = readSnapshot(record.getSnapshotJson());
        if (STATUS_SUCCEEDED.equals(record.getStatus())) {
            return AttemptSubmissionResult.success(snapshot.toAttemptResponse(), true);
        }
        if (STATUS_FAILED_PERMANENT.equals(record.getStatus())) {
            HttpStatus status = onlineSubmit && IDEMPOTENCY_CONFLICT.equals(snapshot.getErrorCode())
                    ? HttpStatus.CONFLICT
                    : HttpStatus.BAD_REQUEST;
            return AttemptSubmissionResult.failed(
                    snapshot.getErrorCode(),
                    snapshot.getErrorMessage(),
                    status,
                    false
            );
        }
        return AttemptSubmissionResult.failed(
                "IDEMPOTENCY_IN_PROGRESS",
                "Attempt is still being processed. Please retry.",
                HttpStatus.CONFLICT,
                true
        );
    }

    private AttemptSubmissionResult handleLegacyAttempt(
            AttemptIdempotencyRecord record,
            QuestionAttempt existingAttempt,
            AttemptRequest request) {
        if (!matchesExistingAttempt(existingAttempt, request)) {
            AttemptSnapshot snapshot = AttemptSnapshot.permanentFailure(
                    request.getAnsweredAt(),
                    IDEMPOTENCY_CONFLICT,
                    "clientRequestId was already used for a different attempt payload."
            );
            markTerminal(
                    record,
                    STATUS_FAILED_PERMANENT,
                    snapshot,
                    existingAttempt.getAttemptId(),
                    IDEMPOTENCY_CONFLICT,
                    snapshot.getErrorMessage()
            );
            return AttemptSubmissionResult.failed(
                    IDEMPOTENCY_CONFLICT,
                    snapshot.getErrorMessage(),
                    HttpStatus.CONFLICT,
                    false
            );
        }

        AttemptSnapshot snapshot = AttemptSnapshot.success(
                existingAttempt.getAttemptId(),
                existingAttempt.isCorrect(),
                "",
                "",
                false,
                existingAttempt.getAnsweredAt()
        );
        markTerminal(record, STATUS_SUCCEEDED, snapshot, existingAttempt.getAttemptId(), null, null);
        return AttemptSubmissionResult.success(snapshot.toAttemptResponse(), true);
    }

    private boolean matchesExistingAttempt(QuestionAttempt attempt, AttemptRequest request) {
        return Objects.equals(attempt.getCourseId(), request.getCourseId()) &&
                Objects.equals(attempt.getLessonId(), request.getLessonId()) &&
                Objects.equals(attempt.getQuestionId(), request.getQuestionId()) &&
                Objects.equals(attempt.getQuestionVersionId(), request.getQuestionVersionId()) &&
                Objects.equals(attempt.getSelectedAnswer(), request.getSelectedAnswer());
    }

    private Optional<String> tryInsertProcessingRecord(String userId, String clientRequestId, String requestHash) {
        String recordId = "idem_" + UUID.randomUUID().toString().replace("-", "");
        LocalDateTime now = LocalDateTime.now();
        try {
            Object inserted = entityManager.createNativeQuery("""
                            INSERT INTO learning_schema.attempt_idempotency_records
                                (record_id, user_id, client_request_id, request_hash, status, created_at, updated_at)
                            VALUES
                                (:recordId, :userId, :clientRequestId, :requestHash, :status, :createdAt, :updatedAt)
                            ON CONFLICT (user_id, client_request_id) DO NOTHING
                            RETURNING record_id
                            """)
                    .setParameter("recordId", recordId)
                    .setParameter("userId", userId)
                    .setParameter("clientRequestId", clientRequestId)
                    .setParameter("requestHash", requestHash)
                    .setParameter("status", STATUS_PROCESSING)
                    .setParameter("createdAt", now)
                    .setParameter("updatedAt", now)
                    .getSingleResult();
            entityManager.flush();
            return Optional.of(inserted.toString());
        } catch (NoResultException e) {
            return Optional.empty();
        }
    }

    private void markTerminal(
            AttemptIdempotencyRecord record,
            String status,
            AttemptSnapshot snapshot,
            String attemptId,
            String errorCode,
            String errorMessage) {
        record.setStatus(status);
        record.setSnapshotJson(writeSnapshot(snapshot));
        record.setAttemptId(attemptId);
        record.setErrorCode(errorCode);
        record.setErrorMessage(errorMessage);
        record.setUpdatedAt(LocalDateTime.now());
        idempotencyRepository.saveAndFlush(record);
    }

    private String hashRequest(String effectiveCourseId, AttemptRequest request) {
        Map<String, Object> canonical = new LinkedHashMap<>();
        canonical.put("answeredAt", normalizeAnsweredAt(request.getAnsweredAt()));
        canonical.put("clientRequestId", normalizeNullable(request.getClientRequestId()));
        canonical.put("courseId", normalizeNullable(effectiveCourseId));
        canonical.put("deviceId", normalizeNullable(request.getDeviceId()));
        canonical.put("lessonId", normalizeNullable(request.getLessonId()));
        canonical.put("lessonVersionId", normalizeNullable(request.getLessonVersionId()));
        canonical.put("questionId", normalizeNullable(request.getQuestionId()));
        canonical.put("questionVersionId", normalizeNullable(request.getQuestionVersionId()));
        canonical.put("responseTimeMs", request.getResponseTimeMs());
        canonical.put("selectedAnswer", normalizeNullable(request.getSelectedAnswer()));
        canonical.put("sourceLanguage", normalizeNullable(request.getSourceLanguage()));
        canonical.put("targetLanguage", normalizeNullable(request.getTargetLanguage()));
        canonical.put("usedHint", request.isUsedHint());

        try {
            String json = canonicalObjectMapper.writeValueAsString(canonical);
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(json.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (JsonProcessingException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Unable to hash attempt request.", e);
        }
    }

    private String normalizeAnsweredAt(LocalDateTime answeredAt) {
        if (answeredAt == null) {
            return "";
        }
        return DateTimeFormatter.ISO_INSTANT.format(answeredAt.atOffset(ZoneOffset.UTC).toInstant());
    }

    private String normalizeNullable(String value) {
        return value == null ? "" : value;
    }

    private String writeSnapshot(AttemptSnapshot snapshot) {
        try {
            return objectMapper.writeValueAsString(snapshot);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Unable to serialize idempotency snapshot.", e);
        }
    }

    private AttemptSnapshot readSnapshot(String snapshotJson) {
        try {
            return objectMapper.readValue(snapshotJson, AttemptSnapshot.class);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Unable to deserialize idempotency snapshot.", e);
        }
    }

    public static class AttemptSubmissionResult {
        private final boolean success;
        private final boolean duplicate;
        private final boolean retryable;
        private final AttemptResponse response;
        private final String errorCode;
        private final String message;
        private final HttpStatus httpStatus;

        private AttemptSubmissionResult(
                boolean success,
                boolean duplicate,
                boolean retryable,
                AttemptResponse response,
                String errorCode,
                String message,
                HttpStatus httpStatus) {
            this.success = success;
            this.duplicate = duplicate;
            this.retryable = retryable;
            this.response = response;
            this.errorCode = errorCode;
            this.message = message;
            this.httpStatus = httpStatus;
        }

        public static AttemptSubmissionResult success(AttemptResponse response, boolean duplicate) {
            return new AttemptSubmissionResult(true, duplicate, false, response, null, null, HttpStatus.OK);
        }

        public static AttemptSubmissionResult failed(String errorCode, String message, HttpStatus httpStatus, boolean retryable) {
            return new AttemptSubmissionResult(false, false, retryable, null, errorCode, message, httpStatus);
        }

        public boolean isSuccess() { return success; }
        public boolean isDuplicate() { return duplicate; }
        public boolean isRetryable() { return retryable; }
        public AttemptResponse getResponse() { return response; }
        public String getErrorCode() { return errorCode; }
        public String getMessage() { return message; }
        public HttpStatus getHttpStatus() { return httpStatus; }
    }

    public static class AttemptSnapshot {
        private String attemptId;
        private boolean isCorrect;
        private String correctAnswer;
        private String explanation;
        private boolean reviewCreatedOrUpdated;
        private String answeredAt;
        private String errorCode;
        private String errorMessage;

        public AttemptSnapshot() {
        }

        public static AttemptSnapshot success(
                String attemptId,
                boolean isCorrect,
                String correctAnswer,
                String explanation,
                boolean reviewCreatedOrUpdated,
                LocalDateTime answeredAt) {
            AttemptSnapshot snapshot = new AttemptSnapshot();
            snapshot.setAttemptId(attemptId);
            snapshot.setCorrect(isCorrect);
            snapshot.setCorrectAnswer(correctAnswer);
            snapshot.setExplanation(explanation);
            snapshot.setReviewCreatedOrUpdated(reviewCreatedOrUpdated);
            snapshot.setAnsweredAt(answeredAt != null
                    ? DateTimeFormatter.ISO_INSTANT.format(answeredAt.atOffset(ZoneOffset.UTC).toInstant())
                    : null);
            return snapshot;
        }

        public static AttemptSnapshot permanentFailure(LocalDateTime answeredAt, String errorCode, String errorMessage) {
            AttemptSnapshot snapshot = new AttemptSnapshot();
            snapshot.setAnsweredAt(answeredAt != null
                    ? DateTimeFormatter.ISO_INSTANT.format(answeredAt.atOffset(ZoneOffset.UTC).toInstant())
                    : null);
            snapshot.setErrorCode(errorCode);
            snapshot.setErrorMessage(errorMessage);
            return snapshot;
        }

        public AttemptResponse toAttemptResponse() {
            return new AttemptResponse(isCorrect, correctAnswer, explanation, reviewCreatedOrUpdated);
        }

        public String getAttemptId() { return attemptId; }
        public void setAttemptId(String attemptId) { this.attemptId = attemptId; }

        public boolean getIsCorrect() { return isCorrect; }
        public void setIsCorrect(boolean correct) { isCorrect = correct; }
        public void setCorrect(boolean correct) { isCorrect = correct; }

        public String getCorrectAnswer() { return correctAnswer; }
        public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = correctAnswer; }

        public String getExplanation() { return explanation; }
        public void setExplanation(String explanation) { this.explanation = explanation; }

        public boolean isReviewCreatedOrUpdated() { return reviewCreatedOrUpdated; }
        public void setReviewCreatedOrUpdated(boolean reviewCreatedOrUpdated) { this.reviewCreatedOrUpdated = reviewCreatedOrUpdated; }

        public String getAnsweredAt() { return answeredAt; }
        public void setAnsweredAt(String answeredAt) { this.answeredAt = answeredAt; }

        public String getErrorCode() { return errorCode; }
        public void setErrorCode(String errorCode) { this.errorCode = errorCode; }

        public String getErrorMessage() { return errorMessage; }
        public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
    }
}
