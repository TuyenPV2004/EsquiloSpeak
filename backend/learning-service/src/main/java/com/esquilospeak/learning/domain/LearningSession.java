package com.esquilospeak.learning.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "learning_sessions", schema = "learning_schema")
public class LearningSession {

    @Id
    @Column(name = "session_id", length = 50)
    private String sessionId;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "course_id", length = 50, nullable = false)
    private String courseId;

    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    public LearningSession() {
    }

    public LearningSession(String sessionId, String userId, String courseId, LocalDateTime startedAt) {
        this.sessionId = sessionId;
        this.userId = userId;
        this.courseId = courseId;
        this.startedAt = startedAt;
    }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }

    public LocalDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(LocalDateTime startedAt) { this.startedAt = startedAt; }

    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
}
