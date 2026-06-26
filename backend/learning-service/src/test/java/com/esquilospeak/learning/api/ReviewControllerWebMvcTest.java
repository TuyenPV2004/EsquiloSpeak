package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.config.InternalServiceAuthInterceptor;
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

    @MockBean
    private InternalServiceAuthInterceptor internalServiceAuthInterceptor;

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
    public void setUp() throws Exception {
        JwtTokenUtil.setSecretKey("ZXNxdWlsb3NwZWFrX3N1cGVyX3NlY3JldF9rZXlfZm9yX212cF90ZXN0aW5nXzEyMzQ1Njc4OTA=");
        
        when(internalServiceAuthInterceptor.preHandle(any(), any(), any())).thenAnswer(invocation -> {
            jakarta.servlet.http.HttpServletRequest req = invocation.getArgument(0);
            jakarta.servlet.http.HttpServletResponse res = invocation.getArgument(1);
            String token = req.getHeader("X-Internal-Service-Token");
            if ("esquilospeak_internal_s2s_token_for_testing_32_bytes_long".equals(token)) {
                return true;
            }
            res.setStatus(403);
            return false;
        });

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

    @Test
    public void testGetDueReviewsCount_S2S_Success() throws Exception {
        ReviewItem item = new ReviewItem("rev_1", "user_123", "en_for_vi", "Hello", "vocabulary", LocalDateTime.now(clock));
        when(reviewItemRepository.findByUserIdAndCourseIdAndNextReviewAtBefore(eq("user_123"), eq("en_for_vi"), any()))
                .thenReturn(Collections.singletonList(item));

        mockMvc.perform(get("/api/v1/internal/courses/en_for_vi/reviews/due/count")
                .header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long")
                .param("userId", "user_123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(1));
    }

    @Test
    public void testGetDueReviewsCount_S2S_MissingToken_ReturnsForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/internal/courses/en_for_vi/reviews/due/count")
                .param("userId", "user_123"))
                .andExpect(status().isForbidden());
    }

    @Test
    public void testGetDueReviewsCount_S2S_MissingUserId_ReturnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/v1/internal/courses/en_for_vi/reviews/due/count")
                .header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long"))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testGetDueReviewsCount_S2S_EmptyUserId_ReturnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/v1/internal/courses/en_for_vi/reviews/due/count")
                .header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long")
                .param("userId", "  "))
                .andExpect(status().isBadRequest());
    }
}
