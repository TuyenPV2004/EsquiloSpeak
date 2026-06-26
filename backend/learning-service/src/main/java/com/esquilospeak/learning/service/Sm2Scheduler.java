package com.esquilospeak.learning.service;

import com.esquilospeak.learning.domain.ReviewItem;
import java.time.Clock;
import java.time.LocalDateTime;

public class Sm2Scheduler {

    public static void calculateNextReview(ReviewItem reviewItem, int q, Clock clock) {
        double easeFactor = reviewItem.getEaseFactor();
        int intervalDays = reviewItem.getIntervalDays();
        int repetitionCount = reviewItem.getRepetitionCount();

        if (q < 3) {
            repetitionCount = 0;
            intervalDays = 0;
            reviewItem.setNextReviewAt(LocalDateTime.now(clock).plusMinutes(10));
            reviewItem.setLapseCount(reviewItem.getLapseCount() + 1);
        } else {
            if (repetitionCount == 0) {
                intervalDays = 1;
            } else if (repetitionCount == 1) {
                intervalDays = 3;
            } else {
                intervalDays = (int) Math.round(intervalDays * easeFactor);
            }
            repetitionCount++;
            reviewItem.setNextReviewAt(LocalDateTime.now(clock).plusDays(intervalDays));
        }

        easeFactor = easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
        if (easeFactor < 1.3) easeFactor = 1.3;

        reviewItem.setEaseFactor(easeFactor);
        reviewItem.setIntervalDays(intervalDays);
        reviewItem.setRepetitionCount(repetitionCount);
        reviewItem.setLastReviewedAt(LocalDateTime.now(clock));
        reviewItem.setLastResult(mapQualityToResult(q));
        reviewItem.setMasteryScore(calculateMastery(repetitionCount, easeFactor, reviewItem.getLapseCount()));
    }

    public static void initializeReviewItem(ReviewItem reviewItem, int q, Clock clock) {
        LocalDateTime nextReview;
        int interval;
        int repCount;

        if (q < 3) {
            nextReview = LocalDateTime.now(clock);
            interval = 0;
            repCount = 0;
            reviewItem.setLapseCount(1);
        } else {
            nextReview = LocalDateTime.now(clock).plusDays(1);
            interval = 1;
            repCount = 1;
            reviewItem.setLapseCount(0);
        }

        reviewItem.setNextReviewAt(nextReview);
        reviewItem.setIntervalDays(interval);
        reviewItem.setRepetitionCount(repCount);
        reviewItem.setEaseFactor(2.5);
        reviewItem.setLastResult(mapQualityToResult(q));
        reviewItem.setMasteryScore(calculateMastery(repCount, 2.5, reviewItem.getLapseCount()));
    }

    public static String mapQualityToResult(int q) {
        if (q < 3) return "again";
        if (q == 3) return "hard";
        if (q == 5) return "easy";
        return "good"; // q == 4
    }

    public static double calculateMastery(int repetitionCount, double easeFactor, int lapseCount) {
        double score = (repetitionCount * 20.0) + (easeFactor * 10.0) - (lapseCount * 15.0);
        return Math.max(0.0, Math.min(100.0, score));
    }
}
