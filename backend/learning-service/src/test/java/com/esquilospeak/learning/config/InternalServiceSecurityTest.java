package com.esquilospeak.learning.config;

import com.esquilospeak.learning.api.ReviewController;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ReviewController.class)
@Import({WebMvcConfig.class, InternalServiceAuthInterceptor.class})
@TestPropertySource(properties = {
    "internal.service.token=esquilospeak_internal_s2s_token_for_testing_32_bytes_long"
})
public class InternalServiceSecurityTest {

    @org.springframework.boot.test.context.TestConfiguration
    static class TestClockConfig {
        @org.springframework.context.annotation.Bean
        @org.springframework.context.annotation.Primary
        public Clock fixedClock() {
            return Clock.fixed(Instant.parse("2026-06-23T00:00:00Z"), ZoneOffset.UTC);
        }
    }

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ReviewItemRepository reviewItemRepository;

    @MockBean
    private ReviewAttemptRepository reviewAttemptRepository;

    @Test
    public void testInternalEndpoint_WithoutToken_Returns403() throws Exception {
        mockMvc.perform(get("/api/v1/internal/courses/en_for_vi/reviews/due/count")
                .param("userId", "user_123"))
                .andExpect(status().isForbidden());
    }

    @Test
    public void testInternalEndpoint_WithValidToken_Returns200() throws Exception {
        when(reviewItemRepository.findByUserIdAndCourseIdAndNextReviewAtBefore(any(), any(), any()))
                .thenReturn(java.util.Collections.emptyList());

        mockMvc.perform(get("/api/v1/internal/courses/en_for_vi/reviews/due/count")
                .header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long")
                .param("userId", "user_123"))
                .andExpect(status().isOk());
    }

    @Test
    public void testPublicEndpoint_DoesNotRequireInternalToken_RequiresJwt() throws Exception {
        mockMvc.perform(get("/api/v1/courses/en_for_vi/reviews/due"))
                .andExpect(status().isUnauthorized()); // from JwtAuthenticationFilter, NOT 403 Forbidden
    }
}
