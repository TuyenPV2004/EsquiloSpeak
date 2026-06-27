package com.esquilospeak.learning.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "lesson_progress",
        schema = "learning_schema",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_lesson_progress_user_lesson",
                        columnNames = {"user_id", "lesson_id"}
                )
        }
)
public class LessonProgress {

    @Id
    @Column(name = "progress_id", length = 50)
    private String progressId;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "lesson_id", length = 50, nullable = false)
    private String lessonId;

    @Column(name = "status", length = 20, nullable = false)
    private String status; // e.g. COMPLETED

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    public LessonProgress() {
    }

    public LessonProgress(String progressId, String userId, String lessonId, String status, LocalDateTime completedAt) {
        this.progressId = progressId;
        this.userId = userId;
        this.lessonId = lessonId;
        this.status = status;
        this.completedAt = completedAt;
    }

    public String getProgressId() { return progressId; }
    public void setProgressId(String progressId) { this.progressId = progressId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getLessonId() { return lessonId; }
    public void setLessonId(String lessonId) { this.lessonId = lessonId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
}
