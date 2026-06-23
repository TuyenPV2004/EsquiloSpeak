package com.esquilospeak.learning.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "review_items", schema = "review_schema")
public class ReviewItem {

    @Id
    @Column(name = "review_item_id", length = 50)
    private String reviewItemId;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "course_id", length = 50, nullable = false)
    private String courseId;

    @Column(name = "concept", nullable = false)
    private String concept;

    @Column(name = "type", length = 50, nullable = false)
    private String type; // vocabulary, sentence, grammar_point, listening_item

    @Column(name = "ease_factor", nullable = false)
    private double easeFactor; // default 2.5

    @Column(name = "interval_days", nullable = false)
    private int intervalDays; // default 0

    @Column(name = "repetition_count", nullable = false)
    private int repetitionCount; // default 0

    @Column(name = "next_review_at", nullable = false)
    private LocalDateTime nextReviewAt;

    @Column(name = "last_reviewed_at")
    private LocalDateTime lastReviewedAt;

    @Column(name = "correct_answer")
    private String correctAnswer;

    @Column(name = "explanation")
    private String explanation;

    public ReviewItem() {
    }

    public ReviewItem(String reviewItemId, String userId, String courseId, String concept, String type, LocalDateTime nextReviewAt) {
        this.reviewItemId = reviewItemId;
        this.userId = userId;
        this.courseId = courseId;
        this.concept = concept;
        this.type = type;
        this.easeFactor = 2.5;
        this.intervalDays = 0;
        this.repetitionCount = 0;
        this.nextReviewAt = nextReviewAt;
    }

    public String getReviewItemId() { return reviewItemId; }
    public void setReviewItemId(String reviewItemId) { this.reviewItemId = reviewItemId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }

    public String getConcept() { return concept; }
    public void setConcept(String concept) { this.concept = concept; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public double getEaseFactor() { return easeFactor; }
    public void setEaseFactor(double easeFactor) { this.easeFactor = easeFactor; }

    public int getIntervalDays() { return intervalDays; }
    public void setIntervalDays(int intervalDays) { this.intervalDays = intervalDays; }

    public int getRepetitionCount() { return repetitionCount; }
    public void setRepetitionCount(int repetitionCount) { this.repetitionCount = repetitionCount; }

    public LocalDateTime getNextReviewAt() { return nextReviewAt; }
    public void setNextReviewAt(LocalDateTime nextReviewAt) { this.nextReviewAt = nextReviewAt; }

    public LocalDateTime getLastReviewedAt() { return lastReviewedAt; }
    public void setLastReviewedAt(LocalDateTime lastReviewedAt) { this.lastReviewedAt = lastReviewedAt; }

    public String getCorrectAnswer() { return correctAnswer; }
    public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = correctAnswer; }

    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }
}
