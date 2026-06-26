package com.esquilospeak.learning.service;

import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class ReviewItemService {
    private static final Logger log = LoggerFactory.getLogger(ReviewItemService.class);

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @Autowired
    private Clock clock;

    @Transactional
    public ReviewItem upsertReviewItemFromAttempt(
            String userId, String courseId, QuestionDto question,
            boolean isCorrect, boolean usedHint, int responseTimeMs, LocalDateTime answeredAt) {
        
        String questionType = determineReviewItemType(question);
        int q = calculateQuality(isCorrect, usedHint, responseTimeMs);

        Optional<ReviewItem> existingOpt = reviewItemRepository
                .findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, question.getQuestionId(), questionType);

        ReviewItem reviewItem;
        if (existingOpt.isPresent()) {
            reviewItem = existingOpt.get();
            // Stale retry guard: Không ghi đè nếu thời gian làm bài cũ hơn/bằng thời điểm đã lưu
            if (answeredAt != null && reviewItem.getLastReviewedAt() != null && !answeredAt.isAfter(reviewItem.getLastReviewedAt())) {
                log.info("Stale retry detected for user {}, learningItem {}. Skipping SRS update.", userId, question.getQuestionId());
                return reviewItem;
            }
            Sm2Scheduler.calculateNextReview(reviewItem, q, clock);
        } else {
            String reviewItemId = "rev_" + UUID.randomUUID().toString().replace("-", "");
            reviewItem = new ReviewItem(reviewItemId, userId, courseId, question.getPrompt(), questionType, LocalDateTime.now(clock));
            Sm2Scheduler.initializeReviewItem(reviewItem, q, clock);
        }

        reviewItem.setCorrectAnswer(question.getCorrectAnswer());
        reviewItem.setExplanation(question.getExplanation());
        reviewItem.setLearningItemId(question.getQuestionId());
        reviewItem.setQuestionVersionId(question.getVersionId()); // Cho phép null cho legacy questions
        if (answeredAt != null) {
            reviewItem.setLastReviewedAt(answeredAt);
        }

        try {
            return reviewItemRepository.saveAndFlush(reviewItem);
        } catch (DataIntegrityViolationException ex) {
            log.warn("Unique constraint violation when saving ReviewItem, retrieving existing one.");
            ReviewItem existing = reviewItemRepository
                    .findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, question.getQuestionId(), questionType)
                    .orElseThrow(() -> ex);

            if (answeredAt != null && existing.getLastReviewedAt() != null && !answeredAt.isAfter(existing.getLastReviewedAt())) {
                return existing;
            }

            // Ghi đè cập nhật an toàn
            updateSrsMetadata(existing, reviewItem);
            return reviewItemRepository.saveAndFlush(existing);
        }
    }

    private void updateSrsMetadata(ReviewItem target, ReviewItem source) {
        target.setCorrectAnswer(source.getCorrectAnswer());
        target.setExplanation(source.getExplanation());
        target.setQuestionVersionId(source.getQuestionVersionId());
        target.setNextReviewAt(source.getNextReviewAt());
        target.setEaseFactor(source.getEaseFactor());
        target.setIntervalDays(source.getIntervalDays());
        target.setRepetitionCount(source.getRepetitionCount());
        target.setMasteryScore(source.getMasteryScore());
        target.setLapseCount(source.getLapseCount());
        target.setLastResult(source.getLastResult());
        target.setLastReviewedAt(source.getLastReviewedAt());
    }

    public String determineReviewItemType(QuestionDto question) {
        String type = question.getType();
        if (type != null) {
            String lowerType = type.trim().toLowerCase();
            if (lowerType.equals("vocabulary") || lowerType.equals("sentence") || 
                lowerType.equals("grammar_point") || lowerType.equals("listening_item")) {
                return lowerType;
            }
        }
        if (question.getAudioUrl() != null && !question.getAudioUrl().trim().isEmpty()) {
            return "listening_item";
        }
        String answer = question.getCorrectAnswer();
        if (answer != null && answer.trim().split("\\s+").length > 2) {
            return "sentence";
        }
        return "vocabulary";
    }

    private int calculateQuality(boolean isCorrect, boolean usedHint, int responseTimeMs) {
        if (!isCorrect) return 1;
        if (usedHint || responseTimeMs > 8000) return 3;
        if (responseTimeMs < 3000) return 5;
        return 4;
    }
}
