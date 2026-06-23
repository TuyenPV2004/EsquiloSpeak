package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.ReviewAttempt;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ReviewController.class)
public class ReviewControllerWebMvcTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @MockBean
    private ReviewItemRepository reviewItemRepository;

    @MockBean
    private ReviewAttemptRepository reviewAttemptRepository;

    @org.springframework.boot.test.context.TestConfiguration
    static class TestClockConfig {
        @org.springframework.context.annotation.Bean
        @org.springframework.context.annotation.Primary
        public Clock fixedClock() {
            return Clock.fixed(Instant.parse("2026-06-23T00:00:00Z"), ZoneOffset.UTC);
        }
    }

    @Autowired
    private Clock clock;

    @Autowired
    private ObjectMapper objectMapper;

    private String validToken;

    @BeforeEach
    public void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(new JwtAuthenticationFilter())
                .build();
        validToken = "Bearer " + JwtTokenUtil.generateToken("user_123", "device_123");
    }

    @Test
    public void testGetDueReviews_ReturnsList() throws Exception {
        ReviewItem item = new ReviewItem("rev_1", "user_123", "en_for_vi", "Hello", "vocabulary", LocalDateTime.now(clock));
        when(reviewItemRepository.findByUserIdAndCourseIdAndNextReviewAtBefore(eq("user_123"), eq("en_for_vi"), any()))
                .thenReturn(Collections.singletonList(item));

        mockMvc.perform(get("/api/v1/courses/en_for_vi/reviews/due")
                .header("Authorization", validToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].reviewItemId").value("rev_1"))
                .andExpect(jsonPath("$[0].concept").value("Hello"));
    }

    @Test
    public void testSubmitReviewAttempt_UpdatesReviewItem() throws Exception {
        ReviewController.ReviewAttemptRequest request = new ReviewController.ReviewAttemptRequest();
        request.setReviewItemId("rev_1");
        request.setRating("good");
        request.setResponseTimeMs(1500);

        ReviewItem item = new ReviewItem("rev_1", "user_123", "en_for_vi", "Hello", "vocabulary", LocalDateTime.now(clock));
        item.setEaseFactor(2.5);
        item.setIntervalDays(1);
        item.setRepetitionCount(1);

        when(reviewItemRepository.findById("rev_1")).thenReturn(Optional.of(item));

        mockMvc.perform(post("/api/v1/courses/en_for_vi/review-attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(reviewItemRepository, times(1)).save(any(ReviewItem.class));
        verify(reviewAttemptRepository, times(1)).save(any(ReviewAttempt.class));
    }

    @Test
    public void testSubmitReviewAttempt_WrongUser_ReturnsForbidden() throws Exception {
        ReviewController.ReviewAttemptRequest request = new ReviewController.ReviewAttemptRequest();
        request.setReviewItemId("rev_1");
        request.setRating("good");
        request.setResponseTimeMs(1500);

        ReviewItem item = new ReviewItem("rev_1", "other_user", "en_for_vi", "Hello", "vocabulary", LocalDateTime.now(clock));

        when(reviewItemRepository.findById("rev_1")).thenReturn(Optional.of(item));

        mockMvc.perform(post("/api/v1/courses/en_for_vi/review-attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());

        verify(reviewItemRepository, never()).save(any(ReviewItem.class));
    }
}
