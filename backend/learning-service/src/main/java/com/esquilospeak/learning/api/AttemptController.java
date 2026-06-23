package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.esquilospeak.learning.util.HmacUtil;
import com.esquilospeak.learning.client.ContentClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.time.Clock;
import com.esquilospeak.learning.service.Sm2Scheduler;

import org.springframework.http.HttpStatus;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class AttemptController {

    private static final Logger log = LoggerFactory.getLogger(AttemptController.class);

    @Value("${analytics.hash-secret}")
    private String hashSecret;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @Autowired
    private ContentClient contentClient;

    @Autowired
    private Clock clock;

    @PostMapping("/courses/{courseId}/attempts")
    public ResponseEntity<?> submitAttempt(
            @PathVariable("courseId") String courseId,
            @RequestAttribute("userId") String userId,
            @RequestBody AttemptRequest request) {

        // 2. Idempotency Check
        Optional<QuestionAttempt> existing = questionAttemptRepository.findByClientRequestId(request.getClientRequestId());
        if (existing.isPresent()) {
            QuestionAttempt attempt = existing.get();
            QuestionDto question = contentClient.getQuestion(attempt.getQuestionId());
            AttemptResponse response = new AttemptResponse(
                    attempt.isCorrect(),
                    question != null ? question.getCorrectAnswer() : "",
                    question != null ? question.getExplanation() : "",
                    false
            );
            return ResponseEntity.ok(response);
        }

        // 3. Fetch Question Details from Content Service
        QuestionDto question = contentClient.getQuestion(request.getQuestionId());
        if (question == null) {
            return ResponseEntity.badRequest().body("Question not found in content-service");
        }

        // 4. Validate speaking self-review attempt
        boolean isCorrect;
        boolean isSpeaking = "speaking".equalsIgnoreCase(question.getType());
        
        if ("SPOKEN_SELF_REVIEWED".equals(request.getSelectedAnswer())) {
            if (!isSpeaking) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("error", Map.of(
                                "code", "INVALID_ATTEMPT_TYPE",
                                "message", "Self-reviewed answers are only allowed for speaking questions."
                        )));
            }
            isCorrect = true;
        } else {
            if (isSpeaking) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("error", Map.of(
                                "code", "INVALID_ATTEMPT_TYPE",
                                "message", "Speaking questions must be answered with SPOKEN_SELF_REVIEWED."
                        )));
            }
            isCorrect = request.getSelectedAnswer() != null &&
                    request.getSelectedAnswer().trim().equalsIgnoreCase(question.getCorrectAnswer().trim());
        }

        // 5. Save Attempt
        String attemptId = "att_" + UUID.randomUUID().toString().replace("-", "");
        QuestionAttempt attempt = new QuestionAttempt(
                attemptId,
                request.getClientRequestId(),
                userId,
                courseId,
                request.getLessonId(),
                request.getQuestionId(),
                request.getQuestionVersionId(),
                request.getSelectedAnswer(),
                isCorrect,
                request.getResponseTimeMs(),
                LocalDateTime.now(clock)
        );
        try {
            questionAttemptRepository.save(attempt);
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            // Unique constraint violation (duplicate clientRequestId), return success response
            return ResponseEntity.ok(new AttemptResponse(
                    isCorrect,
                    question.getCorrectAnswer(),
                    question.getExplanation(),
                    false
            ));
        }

        // 6. SM-2 Spaced Repetition Scheduling
        // Use prompt or questionId as the concept. To keep it clean and identifiable, let's use the prompt
        String concept = question.getPrompt();
        String questionType = "vocabulary";
        
        Optional<ReviewItem> existingReviewOpt = reviewItemRepository.findByUserIdAndCourseIdAndConcept(userId, courseId, concept);
        boolean reviewCreatedOrUpdated = false;

        // We create or update review item if wrong, slow, used hint, or to schedule future review
        if (!isSpeaking && (!isCorrect || request.isUsedHint() || request.getResponseTimeMs() > 8000 || existingReviewOpt.isPresent())) {
            ReviewItem reviewItem;
            
            // Map performance to quality q (0-5)
            int q;
            if (!isCorrect) {
                q = 1; // again
            } else if (request.isUsedHint() || request.getResponseTimeMs() > 8000) {
                q = 3; // hard
            } else if (request.getResponseTimeMs() < 3000) {
                q = 5; // easy
            } else {
                q = 4; // good
            }

            if (existingReviewOpt.isPresent()) {
                reviewItem = existingReviewOpt.get();
                Sm2Scheduler.calculateNextReview(reviewItem, q, clock);
            } else {
                String reviewItemId = "rev_" + UUID.randomUUID().toString().replace("-", "");
                reviewItem = new ReviewItem(
                        reviewItemId,
                        userId,
                        courseId,
                        concept,
                        questionType,
                        LocalDateTime.now(clock)
                );
                Sm2Scheduler.initializeReviewItem(reviewItem, q, clock);
            }

            reviewItem.setCorrectAnswer(question.getCorrectAnswer());
            reviewItem.setExplanation(question.getExplanation());
            reviewItemRepository.save(reviewItem);
            reviewCreatedOrUpdated = true;
        }

        AttemptResponse response = new AttemptResponse(
                isCorrect,
                question.getCorrectAnswer(),
                question.getExplanation(),
                reviewCreatedOrUpdated
        );

        String userHash = HmacUtil.hashUserId(userId, hashSecret);
        log.info("{\"type\":\"analytics\",\"eventName\":\"attempt_submitted\",\"userHash\":\"{}\",\"courseId\":\"{}\",\"lessonId\":\"{}\",\"questionType\":\"{}\",\"resultCategory\":\"{}\"}",
                userHash, courseId, request.getLessonId(), question.getType(), isSpeaking ? "completion_only" : (isCorrect ? "correct" : "incorrect"));

        return ResponseEntity.ok(response);
    }



    // DTO Classes
    public static class AttemptRequest {
        private String clientRequestId;
        private String deviceId;
        private String courseId;
        private String sourceLanguage;
        private String targetLanguage;
        private String lessonId;
        private String lessonVersionId;
        private String questionId;
        private String questionVersionId;
        private String selectedAnswer;
        private int responseTimeMs;
        private boolean usedHint;
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
        public boolean getReviewCreated() { return reviewCreated; }
    }

    public static class QuestionDto {
        private String questionId;
        private String correctAnswer;
        private String explanation;
        private String prompt;
        private String type;
        private String versionId;

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
    }
}
