package com.esquilospeak.auth.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_profiles", schema = "user_schema")
public class UserProfile {

    @Id
    @Column(name = "user_id", length = 36)
    private String userId;

    @Column(name = "target_language", length = 10)
    private String targetLanguage;

    @Column(name = "source_language", length = 10)
    private String sourceLanguage;

    @Column(name = "daily_goal_minutes")
    private Integer dailyGoalMinutes;

    @Column(name = "self_assessed_level", length = 10)
    private String selfAssessedLevel;

    @Column(name = "onboarding_completed")
    private boolean onboardingCompleted;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public UserProfile() {
    }

    public UserProfile(String userId, LocalDateTime createdAt) {
        this.userId = userId;
        this.createdAt = createdAt;
        this.onboardingCompleted = false;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getTargetLanguage() {
        return targetLanguage;
    }

    public void setTargetLanguage(String targetLanguage) {
        this.targetLanguage = targetLanguage;
    }

    public String getSourceLanguage() {
        return sourceLanguage;
    }

    public void setSourceLanguage(String sourceLanguage) {
        this.sourceLanguage = sourceLanguage;
    }

    public Integer getDailyGoalMinutes() {
        return dailyGoalMinutes;
    }

    public void setDailyGoalMinutes(Integer dailyGoalMinutes) {
        this.dailyGoalMinutes = dailyGoalMinutes;
    }

    public String getSelfAssessedLevel() {
        return selfAssessedLevel;
    }

    public void setSelfAssessedLevel(String selfAssessedLevel) {
        this.selfAssessedLevel = selfAssessedLevel;
    }

    public boolean isOnboardingCompleted() {
        return onboardingCompleted;
    }

    public void setOnboardingCompleted(boolean onboardingCompleted) {
        this.onboardingCompleted = onboardingCompleted;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
