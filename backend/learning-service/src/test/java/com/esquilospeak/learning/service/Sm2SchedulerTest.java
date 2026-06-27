package com.esquilospeak.learning.service;

import com.esquilospeak.learning.domain.ReviewItem;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import static org.junit.jupiter.api.Assertions.*;

public class Sm2SchedulerTest {

    private Clock clock;
    private LocalDateTime fixedNow;

    @BeforeEach
    public void setUp() {
        clock = Clock.fixed(Instant.parse("2026-06-23T00:00:00Z"), ZoneOffset.UTC);
        fixedNow = LocalDateTime.now(clock);
    }

    @Test
    public void testInitializeReviewItem_QualityLessThan3_Again() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        Sm2Scheduler.initializeReviewItem(item, 1, clock);

        assertEquals(fixedNow, item.getNextReviewAt());
        assertEquals(0, item.getIntervalDays());
        assertEquals(0, item.getRepetitionCount());
        assertEquals(2.5, item.getEaseFactor());
        assertEquals(1, item.getLapseCount());
        assertEquals("again", item.getLastResult());
        assertEquals(10.0, item.getMasteryScore());
    }

    @Test
    public void testInitializeReviewItem_Quality3OrMore_Good() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        Sm2Scheduler.initializeReviewItem(item, 4, clock);

        assertEquals(fixedNow.plusDays(1), item.getNextReviewAt());
        assertEquals(1, item.getIntervalDays());
        assertEquals(1, item.getRepetitionCount());
        assertEquals(2.5, item.getEaseFactor());
        assertEquals(0, item.getLapseCount());
        assertEquals("good", item.getLastResult());
        assertEquals(45.0, item.getMasteryScore());
    }

    @Test
    public void testCalculateNextReview_QualityLessThan3_Again() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        item.setEaseFactor(2.5);
        item.setIntervalDays(3);
        item.setRepetitionCount(2);

        Sm2Scheduler.calculateNextReview(item, 1, clock);

        assertEquals(0, item.getIntervalDays());
        assertEquals(0, item.getRepetitionCount());
        assertEquals(fixedNow.plusMinutes(10), item.getNextReviewAt());
        // EF calculation: 2.5 + (0.1 - (5 - 1) * (0.08 + (5 - 1) * 0.02)) = 1.96
        assertEquals(1.96, item.getEaseFactor(), 0.01);
        assertEquals(1, item.getLapseCount());
        assertEquals("again", item.getLastResult());
        assertEquals(4.6, item.getMasteryScore(), 0.01);
    }

    @Test
    public void testCalculateNextReview_Quality3_Hard() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        item.setEaseFactor(2.5);
        item.setIntervalDays(1);
        item.setRepetitionCount(1);

        Sm2Scheduler.calculateNextReview(item, 3, clock);

        assertEquals(2, item.getRepetitionCount());
        assertEquals(3, item.getIntervalDays());
        assertEquals(fixedNow.plusDays(3), item.getNextReviewAt());
        assertEquals(2.36, item.getEaseFactor(), 0.01);
        assertEquals(0, item.getLapseCount());
        assertEquals("hard", item.getLastResult());
        assertEquals(63.6, item.getMasteryScore(), 0.01);
    }

    @Test
    public void testCalculateNextReview_Quality4_Good() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        item.setEaseFactor(2.5);
        item.setIntervalDays(3);
        item.setRepetitionCount(2);

        Sm2Scheduler.calculateNextReview(item, 4, clock);

        assertEquals(3, item.getRepetitionCount());
        assertEquals(8, item.getIntervalDays());
        assertEquals(fixedNow.plusDays(8), item.getNextReviewAt());
        assertEquals(2.5, item.getEaseFactor(), 0.01);
        assertEquals(0, item.getLapseCount());
        assertEquals("good", item.getLastResult());
        assertEquals(85.0, item.getMasteryScore(), 0.01);
    }

    @Test
    public void testCalculateNextReview_Quality5_Easy() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        item.setEaseFactor(2.5);
        item.setIntervalDays(8);
        item.setRepetitionCount(3);

        Sm2Scheduler.calculateNextReview(item, 5, clock);

        assertEquals(4, item.getRepetitionCount());
        assertEquals(20, item.getIntervalDays());
        assertEquals(fixedNow.plusDays(20), item.getNextReviewAt());
        assertEquals(2.6, item.getEaseFactor(), 0.01);
        assertEquals(0, item.getLapseCount());
        assertEquals("easy", item.getLastResult());
        assertEquals(100.0, item.getMasteryScore(), 0.01);
    }

    @Test
    public void testCalculateNextReview_EaseFactorMinimumBound() {
        ReviewItem item = new ReviewItem("rev_1", "user_1", "en_for_vi", "hello", "vocabulary", fixedNow);
        item.setEaseFactor(1.3);
        item.setIntervalDays(1);
        item.setRepetitionCount(1);

        Sm2Scheduler.calculateNextReview(item, 1, clock);

        assertTrue(item.getEaseFactor() >= 1.3);
        assertEquals(1.3, item.getEaseFactor(), 0.01);
        assertEquals(1, item.getLapseCount());
        assertEquals("again", item.getLastResult());
        assertEquals(0.0, item.getMasteryScore());
    }

    @Test
    public void testCalculateMastery_ClampsToZeroAndOneHundred() {
        assertEquals(0.0, Sm2Scheduler.calculateMastery(0, 1.3, 10));
        assertEquals(100.0, Sm2Scheduler.calculateMastery(10, 3.0, 0));
    }
}
