package com.esquilospeak.learning.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "question_attempts", 
    schema = "learning_schema",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "client_request_id"})
    }
)
public class QuestionAttempt {

    @Id
    @Column(name = "attempt_id", length = 50)
    private String attemptId;

    @Column(name = "client_request_id", length = 50, nullable = false)
    private String clientRequestId;

    @Column(name = "user_id", length = 50, nullable = false)
    private String userId;

    @Column(name = "course_id", length = 50, nullable = false)
    private String courseId;

    @Column(name = "lesson_id", length = 50, nullable = false)
    private String lessonId;

    @Column(name = "question_id", length = 50, nullable = false)
    private String questionId;

    @Column(name = "question_version_id", length = 50)
    private String questionVersionId;

    @Column(name = "selected_answer")
    private String selectedAnswer;

    @Column(name = "is_correct", nullable = false)
    private boolean isCorrect;

    @Column(name = "response_time_ms")
    private int responseTimeMs;

    @Column(name = "answered_at", nullable = false)
    private LocalDateTime answeredAt;

    public QuestionAttempt() {
    }

    public QuestionAttempt(String attemptId, String clientRequestId, String userId, String courseId, 
                           String lessonId, String questionId, String questionVersionId, String selectedAnswer, 
                           boolean isCorrect, int responseTimeMs, LocalDateTime answeredAt) {
        this.attemptId = attemptId;
        this.clientRequestId = clientRequestId;
        this.userId = userId;
        this.courseId = courseId;
        this.lessonId = lessonId;
        this.questionId = questionId;
        this.questionVersionId = questionVersionId;
        this.selectedAnswer = selectedAnswer;
        this.isCorrect = isCorrect;
        this.responseTimeMs = responseTimeMs;
        this.answeredAt = answeredAt;
    }

    public String getAttemptId() { return attemptId; }
    public void setAttemptId(String attemptId) { this.attemptId = attemptId; }

    public String getClientRequestId() { return clientRequestId; }
    public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }

    public String getLessonId() { return lessonId; }
    public void setLessonId(String lessonId) { this.lessonId = lessonId; }

    public String getQuestionId() { return questionId; }
    public void setQuestionId(String questionId) { this.questionId = questionId; }

    public String getQuestionVersionId() { return questionVersionId; }
    public void setQuestionVersionId(String questionVersionId) { this.questionVersionId = questionVersionId; }

    public String getSelectedAnswer() { return selectedAnswer; }
    public void setSelectedAnswer(String selectedAnswer) { this.selectedAnswer = selectedAnswer; }

    public boolean isCorrect() { return isCorrect; }
    public void setCorrect(boolean correct) { isCorrect = correct; }

    public int getResponseTimeMs() { return responseTimeMs; }
    public void setResponseTimeMs(int responseTimeMs) { this.responseTimeMs = responseTimeMs; }

    public LocalDateTime getAnsweredAt() { return answeredAt; }
    public void setAnsweredAt(LocalDateTime answeredAt) { this.answeredAt = answeredAt; }
}
