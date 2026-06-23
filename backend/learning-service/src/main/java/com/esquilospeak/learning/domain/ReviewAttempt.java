package com.esquilospeak.learning.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "review_attempts", schema = "review_schema")
public class ReviewAttempt {

    @Id
    @Column(name = "attempt_id", length = 50)
    private String attemptId;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "review_item_id", length = 50, nullable = false)
    private String reviewItemId;

    @Column(name = "rating", length = 20, nullable = false)
    private String rating; // again, hard, good, easy

    @Column(name = "response_time_ms")
    private int responseTimeMs;

    @Column(name = "reviewed_at", nullable = false)
    private LocalDateTime reviewedAt;

    public ReviewAttempt() {
    }

    public ReviewAttempt(String attemptId, String userId, String reviewItemId, String rating, int responseTimeMs, LocalDateTime reviewedAt) {
        this.attemptId = attemptId;
        this.userId = userId;
        this.reviewItemId = reviewItemId;
        this.rating = rating;
        this.responseTimeMs = responseTimeMs;
        this.reviewedAt = reviewedAt;
    }

    public String getAttemptId() { return attemptId; }
    public void setAttemptId(String attemptId) { this.attemptId = attemptId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getReviewItemId() { return reviewItemId; }
    public void setReviewItemId(String reviewItemId) { this.reviewItemId = reviewItemId; }

    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }

    public int getResponseTimeMs() { return responseTimeMs; }
    public void setResponseTimeMs(int responseTimeMs) { this.responseTimeMs = responseTimeMs; }

    public LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(LocalDateTime reviewedAt) { this.reviewedAt = reviewedAt; }
}
