package com.esquilospeak.auth.api;

import com.esquilospeak.auth.domain.UserProfile;
import com.esquilospeak.auth.infrastructure.UserProfileRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/v1")
public class UserController {

    @Autowired
    private UserProfileRepository userProfileRepository;

    @PostMapping("/onboarding")
    public ResponseEntity<OnboardingResponse> saveOnboarding(
            HttpServletRequest request,
            @RequestBody OnboardingRequest onboardingRequest) {
        
        String userId = (String) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        UserProfile profile = userProfileRepository.findById(userId)
                .orElseGet(() -> new UserProfile(userId, LocalDateTime.now()));

        profile.setTargetLanguage(onboardingRequest.getTargetLanguage());
        profile.setSourceLanguage(onboardingRequest.getSourceLanguage());
        profile.setDailyGoalMinutes(onboardingRequest.getDailyGoalMinutes());
        profile.setSelfAssessedLevel(onboardingRequest.getSelfAssessedLevel());
        profile.setOnboardingCompleted(true);
        profile.setUpdatedAt(LocalDateTime.now());

        userProfileRepository.save(profile);

        return ResponseEntity.ok(new OnboardingResponse(true, userId));
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileResponse> getMe(HttpServletRequest request) {
        String userId = (String) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }

        UserProfile profile = userProfileRepository.findById(userId)
                .orElse(null);

        if (profile == null) {
            return ResponseEntity.notFound().build();
        }

        UserProfileResponse response = new UserProfileResponse(
                profile.getUserId(),
                profile.getTargetLanguage(),
                profile.getSourceLanguage(),
                profile.getDailyGoalMinutes(),
                profile.getSelfAssessedLevel(),
                profile.isOnboardingCompleted(),
                profile.getCreatedAt()
        );
        return ResponseEntity.ok(response);
    }

    public static class OnboardingRequest {
        private String targetLanguage;
        private String sourceLanguage;
        private Integer dailyGoalMinutes;
        private String selfAssessedLevel;

        public String getTargetLanguage() { return targetLanguage; }
        public void setTargetLanguage(String targetLanguage) { this.targetLanguage = targetLanguage; }

        public String getSourceLanguage() { return sourceLanguage; }
        public void setSourceLanguage(String sourceLanguage) { this.sourceLanguage = sourceLanguage; }

        public Integer getDailyGoalMinutes() { return dailyGoalMinutes; }
        public void setDailyGoalMinutes(Integer dailyGoalMinutes) { this.dailyGoalMinutes = dailyGoalMinutes; }

        public String getSelfAssessedLevel() { return selfAssessedLevel; }
        public void setSelfAssessedLevel(String selfAssessedLevel) { this.selfAssessedLevel = selfAssessedLevel; }
    }

    public static class OnboardingResponse {
        private boolean success;
        private String userId;

        public OnboardingResponse(boolean success, String userId) {
            this.success = success;
            this.userId = userId;
        }

        public boolean isSuccess() { return success; }
        public String getUserId() { return userId; }
    }

    public static class UserProfileResponse {
        private String userId;
        private String targetLanguage;
        private String sourceLanguage;
        private Integer dailyGoalMinutes;
        private String selfAssessedLevel;
        private boolean onboardingCompleted;
        private LocalDateTime createdAt;

        public UserProfileResponse(String userId, String targetLanguage, String sourceLanguage, 
                                  Integer dailyGoalMinutes, String selfAssessedLevel, 
                                  boolean onboardingCompleted, LocalDateTime createdAt) {
            this.userId = userId;
            this.targetLanguage = targetLanguage;
            this.sourceLanguage = sourceLanguage;
            this.dailyGoalMinutes = dailyGoalMinutes;
            this.selfAssessedLevel = selfAssessedLevel;
            this.onboardingCompleted = onboardingCompleted;
            this.createdAt = createdAt;
        }

        public String getUserId() { return userId; }
        public String getTargetLanguage() { return targetLanguage; }
        public String getSourceLanguage() { return sourceLanguage; }
        public Integer getDailyGoalMinutes() { return dailyGoalMinutes; }
        public String getSelfAssessedLevel() { return selfAssessedLevel; }
        public boolean isOnboardingCompleted() { return onboardingCompleted; }
        public LocalDateTime getCreatedAt() { return createdAt; }
    }
}
