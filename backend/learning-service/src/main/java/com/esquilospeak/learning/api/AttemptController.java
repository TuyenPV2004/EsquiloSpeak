package com.esquilospeak.learning.api;

import com.esquilospeak.learning.service.AttemptSubmissionOperations;
import com.esquilospeak.learning.service.AttemptSubmissionService.AttemptSubmissionResult;
import com.esquilospeak.learning.util.HmacUtil;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/v1")
public class AttemptController {

    private static final Logger log = LoggerFactory.getLogger(AttemptController.class);

    @Value("${analytics.hash-secret}")
    private String hashSecret;

    @Autowired
    private AttemptSubmissionOperations attemptSubmissionService;

    @PostMapping("/courses/{courseId}/attempts")
    public ResponseEntity<?> submitAttempt(
            @PathVariable("courseId") String courseId,
            @RequestAttribute("userId") String userId,
            @Valid @RequestBody AttemptRequest request) {

        AttemptSubmissionResult result = attemptSubmissionService.submitOnlineAttempt(userId, courseId, request);
        if (!result.isSuccess()) {
            return ResponseEntity.status(result.getHttpStatus())
                    .body(ApiErrorResponse.of(result.getErrorCode(), result.getMessage()));
        }

        String userHash = HmacUtil.hashUserId(userId, hashSecret);
        log.info("{\"type\":\"analytics\",\"eventName\":\"attempt_submitted\",\"userHash\":\"{}\",\"courseId\":\"{}\",\"lessonId\":\"{}\",\"questionId\":\"{}\",\"resultCategory\":\"{}\"}",
                userHash,
                courseId,
                request.getLessonId(),
                request.getQuestionId(),
                result.getResponse().getIsCorrect() ? "correct" : "incorrect");

        return ResponseEntity.ok(result.getResponse());
    }

    public static class AttemptRequest {
        @NotBlank
        private String clientRequestId;
        @NotBlank
        private String deviceId;
        @NotBlank
        private String courseId;
        private String sourceLanguage;
        private String targetLanguage;
        @NotBlank
        private String lessonId;
        @NotBlank
        private String lessonVersionId;
        @NotBlank
        private String questionId;
        @NotBlank
        private String questionVersionId;
        private String selectedAnswer;
        private int responseTimeMs;
        private boolean usedHint;
        @NotNull
        private LocalDateTime answeredAt;

        public String getClientRequestId() { return clientRequestId; }
        public void setClientRequestId(String clientRequestId) { this.clientRequestId = clientRequestId; }

        public String getDeviceId() { return deviceId; }
        public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

        public String getCourseId() { return courseId; }
        public void setCourseId(String courseId) { this.courseId = courseId; }

        public String getSourceLanguage() { return sourceLanguage; }
        public void setSourceLanguage(String sourceLanguage) { this.sourceLanguage = sourceLanguage; }

        public String getTargetLanguage() { return targetLanguage; }
        public void setTargetLanguage(String targetLanguage) { this.targetLanguage = targetLanguage; }

        public String getLessonId() { return lessonId; }
        public void setLessonId(String lessonId) { this.lessonId = lessonId; }

        public String getLessonVersionId() { return lessonVersionId; }
        public void setLessonVersionId(String lessonVersionId) { this.lessonVersionId = lessonVersionId; }

        public String getQuestionId() { return questionId; }
        public void setQuestionId(String questionId) { this.questionId = questionId; }

        public String getQuestionVersionId() { return questionVersionId; }
        public void setQuestionVersionId(String questionVersionId) { this.questionVersionId = questionVersionId; }

        public String getSelectedAnswer() { return selectedAnswer; }
        public void setSelectedAnswer(String selectedAnswer) { this.selectedAnswer = selectedAnswer; }

        public int getResponseTimeMs() { return responseTimeMs; }
        public void setResponseTimeMs(int responseTimeMs) { this.responseTimeMs = responseTimeMs; }

        public boolean isUsedHint() { return usedHint; }
        public void setUsedHint(boolean usedHint) { this.usedHint = usedHint; }

        public LocalDateTime getAnsweredAt() { return answeredAt; }
        public void setAnsweredAt(LocalDateTime answeredAt) { this.answeredAt = answeredAt; }
    }

    public static class AttemptResponse {
        private boolean isCorrect;
        private String correctAnswer;
        private String explanation;
        private boolean reviewCreated;

        public AttemptResponse(boolean isCorrect, String correctAnswer, String explanation, boolean reviewCreated) {
            this.isCorrect = isCorrect;
            this.correctAnswer = correctAnswer;
            this.explanation = explanation;
            this.reviewCreated = reviewCreated;
        }

        public boolean getIsCorrect() { return isCorrect; }
        public String getCorrectAnswer() { return correctAnswer; }
        public String getExplanation() { return explanation; }
        public boolean isReviewCreated() { return reviewCreated; }
    }

    public static class QuestionDto {
        private String questionId;
        private String correctAnswer;
        private String explanation;
        private String prompt;
        private String type;
        private String versionId;
        private String audioUrl;

        public String getQuestionId() { return questionId; }
        public void setQuestionId(String questionId) { this.questionId = questionId; }

        public String getCorrectAnswer() { return correctAnswer; }
        public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = correctAnswer; }

        public String getExplanation() { return explanation; }
        public void setExplanation(String explanation) { this.explanation = explanation; }

        public String getPrompt() { return prompt; }
        public void setPrompt(String prompt) { this.prompt = prompt; }

        public String getType() { return type; }
        public void setType(String type) { this.type = type; }

        public String getVersionId() { return versionId; }
        public void setVersionId(String versionId) { this.versionId = versionId; }

        public String getAudioUrl() { return audioUrl; }
        public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }
    }
}
