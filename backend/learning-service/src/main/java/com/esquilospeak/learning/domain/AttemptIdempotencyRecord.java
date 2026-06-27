package com.esquilospeak.learning.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "attempt_idempotency_records",
        schema = "learning_schema",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_attempt_idempotency_user_client_request",
                        columnNames = {"user_id", "client_request_id"}
                )
        }
)
public class AttemptIdempotencyRecord {

    @Id
    @Column(name = "record_id", length = 50)
    private String recordId;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "client_request_id", length = 50, nullable = false)
    private String clientRequestId;

    @Column(name = "request_hash", length = 64, nullable = false)
    private String requestHash;

    @Column(name = "status", length = 30, nullable = false)
    private String status;

    @Lob
    @Column(name = "snapshot_json")
    private String snapshotJson;

    @Column(name = "attempt_id", length = 50)
    private String attemptId;

    @Column(name = "error_code", length = 80)
    private String errorCode;

    @Column(name = "error_message", length = 500)
    private String errorMessage;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public AttemptIdempotencyRecord() {
    }

    public String getRecordId() { return recordId; }
    public void setRecordId(String recordId) { this.recordId = recordId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }

    public String getRequestHash() { return requestHash; }
    public void setRequestHash(String requestHash) { this.requestHash = requestHash; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getSnapshotJson() { return snapshotJson; }
    public void setSnapshotJson(String snapshotJson) { this.snapshotJson = snapshotJson; }

    public String getAttemptId() { return attemptId; }
    public void setAttemptId(String attemptId) { this.attemptId = attemptId; }

    public String getErrorCode() { return errorCode; }
    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
