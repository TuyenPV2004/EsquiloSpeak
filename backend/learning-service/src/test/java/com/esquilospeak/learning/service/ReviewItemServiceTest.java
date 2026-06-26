package com.esquilospeak.learning.service;

import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ReviewItemServiceTest {

    @Mock
    private ReviewItemRepository reviewItemRepository;

    @InjectMocks
    private ReviewItemService reviewItemService;

    private Clock fixedClock;
    private LocalDateTime fixedNow;
    private String userId = "user_test";
    private String courseId = "en_for_vi";

    @BeforeEach
    public void setUp() throws Exception {
        fixedClock = Clock.fixed(Instant.parse("2026-06-23T00:00:00Z"), ZoneOffset.UTC);
        fixedNow = LocalDateTime.now(fixedClock);
        
        // Inject concrete Clock instance directly into the clock field via reflection
        java.lang.reflect.Field clockField = ReviewItemService.class.getDeclaredField("clock");
        clockField.setAccessible(true);
        clockField.set(reviewItemService, fixedClock);
    }

    @Test
    public void testUpsertReviewItemFromAttempt_NewItem() {
        QuestionDto question = new QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Apple");
        question.setExplanation("An apple");
        question.setPrompt("Quả táo");
        question.setType("vocabulary");
        question.setVersionId("q_1_v1");

        when(reviewItemRepository.findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, "q_1", "vocabulary"))
                .thenReturn(Optional.empty());
        when(reviewItemRepository.saveAndFlush(any(ReviewItem.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ReviewItem result = reviewItemService.upsertReviewItemFromAttempt(
                userId, courseId, question, true, false, 1500, fixedNow
        );

        assertNotNull(result);
        assertEquals("q_1", result.getLearningItemId());
        assertEquals("vocabulary", result.getType());
        assertEquals("q_1_v1", result.getQuestionVersionId());
        assertEquals("Apple", result.getCorrectAnswer());
        assertEquals(fixedNow, result.getLastReviewedAt());
        verify(reviewItemRepository, times(1)).saveAndFlush(any(ReviewItem.class));
    }

    @Test
    public void testUpsertReviewItemFromAttempt_ExistingItem() {
        QuestionDto question = new QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Apple");
        question.setPrompt("Quả táo");
        question.setType("vocabulary");
        question.setVersionId("q_1_v2");

        ReviewItem existing = new ReviewItem("rev_1", userId, courseId, "Quả táo", "vocabulary", fixedNow.minusDays(1));
        existing.setLearningItemId("q_1");
        existing.setQuestionVersionId("q_1_v1");
        existing.setLastReviewedAt(fixedNow.minusDays(1));

        when(reviewItemRepository.findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, "q_1", "vocabulary"))
                .thenReturn(Optional.of(existing));
        when(reviewItemRepository.saveAndFlush(any(ReviewItem.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ReviewItem result = reviewItemService.upsertReviewItemFromAttempt(
                userId, courseId, question, true, false, 1500, fixedNow
        );

        assertNotNull(result);
        assertEquals("q_1_v2", result.getQuestionVersionId());
        assertEquals(fixedNow, result.getLastReviewedAt());
        assertEquals(1, result.getRepetitionCount()); // SM-2 calculations applied
    }

    @Test
    public void testUpsertReviewItemFromAttempt_StaleRetryGuard() {
        QuestionDto question = new QuestionDto();
        question.setQuestionId("q_1");
        question.setPrompt("Quả táo");
        question.setType("vocabulary");

        ReviewItem existing = new ReviewItem("rev_1", userId, courseId, "Quả táo", "vocabulary", fixedNow);
        existing.setLearningItemId("q_1");
        existing.setLastReviewedAt(fixedNow);
        existing.setRepetitionCount(2);

        when(reviewItemRepository.findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, "q_1", "vocabulary"))
                .thenReturn(Optional.of(existing));

        // an answeredAt timestamp in the past (fixedNow - 2 hours)
        LocalDateTime staleAnsweredAt = fixedNow.minusHours(2);

        ReviewItem result = reviewItemService.upsertReviewItemFromAttempt(
                userId, courseId, question, true, false, 1000, staleAnsweredAt
        );

        assertNotNull(result);
        // Ensure SM-2 schedule was not updated (repetition count remains 2)
        assertEquals(2, result.getRepetitionCount());
        verify(reviewItemRepository, never()).saveAndFlush(any(ReviewItem.class));
    }

    @Test
    public void testUpsertReviewItemFromAttempt_DataIntegrityViolation_IdempotentRecovery() {
        QuestionDto question = new QuestionDto();
        question.setQuestionId("q_1");
        question.setPrompt("Quả táo");
        question.setType("vocabulary");
        question.setVersionId("q_1_v1");

        ReviewItem existing = new ReviewItem("rev_1", userId, courseId, "Quả táo", "vocabulary", fixedNow.minusDays(1));
        existing.setLearningItemId("q_1");
        existing.setQuestionVersionId("q_1_v1");
        existing.setLastReviewedAt(fixedNow.minusDays(1));

        when(reviewItemRepository.findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, "q_1", "vocabulary"))
                .thenReturn(Optional.empty()) // Find doesn't see it due to race condition
                .thenReturn(Optional.of(existing)); // Catch block sees it

        // Save throws unique constraint violation only for the first save (the new item, not rev_1)
        doThrow(new DataIntegrityViolationException("Unique constraint violation"))
                .when(reviewItemRepository).saveAndFlush(argThat(item -> item != null && !"rev_1".equals(item.getReviewItemId())));
        // Successful save for existing item (rev_1)
        when(reviewItemRepository.saveAndFlush(argThat(item -> item != null && "rev_1".equals(item.getReviewItemId()))))
                .thenAnswer(invocation -> invocation.getArgument(0));

        ReviewItem result = reviewItemService.upsertReviewItemFromAttempt(
                userId, courseId, question, true, false, 1500, fixedNow
        );

        assertNotNull(result);
        assertEquals("rev_1", result.getReviewItemId());
        assertEquals(fixedNow, result.getLastReviewedAt());
        verify(reviewItemRepository, times(2)).saveAndFlush(any(ReviewItem.class)); // 1 fail, 1 catch update
    }

    @Test
    public void testUpsertReviewItemFromAttempt_NullVersionSupported() {
        QuestionDto question = new QuestionDto();
        question.setQuestionId("q_1");
        question.setPrompt("Quả táo");
        question.setType("vocabulary");
        question.setVersionId(null); // legacy null version

        when(reviewItemRepository.findByUserIdAndCourseIdAndLearningItemIdAndType(userId, courseId, "q_1", "vocabulary"))
                .thenReturn(Optional.empty());
        when(reviewItemRepository.saveAndFlush(any(ReviewItem.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ReviewItem result = reviewItemService.upsertReviewItemFromAttempt(
                userId, courseId, question, true, false, 1500, fixedNow
        );

        assertNotNull(result);
        assertNull(result.getQuestionVersionId());
        verify(reviewItemRepository, times(1)).saveAndFlush(any(ReviewItem.class));
    }
}
