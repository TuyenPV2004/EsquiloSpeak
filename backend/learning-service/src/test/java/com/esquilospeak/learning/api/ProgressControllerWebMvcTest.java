package com.esquilospeak.learning.api;

import com.esquilospeak.learning.client.ContentClient;
import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.infrastructure.LessonProgressRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.esquilospeak.learning.service.ProgressService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.server.ResponseStatusException;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(value = ProgressController.class, properties = {
        "internal.service.token=esquilospeak_internal_s2s_token_for_testing_32_bytes_long",
        "analytics.hash-secret=dev-only-fallback-secret-key-1234567890"
})
public class ProgressControllerWebMvcTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @MockBean
    private LessonProgressRepository lessonProgressRepository;

    @MockBean
    private QuestionAttemptRepository questionAttemptRepository;

    @MockBean
    private ReviewAttemptRepository reviewAttemptRepository;

    @MockBean
    private ReviewItemRepository reviewItemRepository;

    @MockBean
    private ContentClient contentClient;

    @MockBean
    private ProgressService progressService;

    private String validToken;

    @BeforeEach
    public void setUp() {
        JwtTokenUtil.setSecretKey("ZXNxdWlsb3NwZWFrX3N1cGVyX3NlY3JldF9rZXlfZm9yX212cF90ZXN0aW5nXzEyMzQ1Njc4OTA=");

        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(new JwtAuthenticationFilter())
                .build();
        validToken = "Bearer " + JwtTokenUtil.generateToken("user_123", "device_123");
    }

    @Test
    public void testCompleteLesson_Success() throws Exception {
        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete")
                .header("Authorization", validToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(progressService).completeLesson("user_123", "en_for_vi", "lesson_1");
    }

    @Test
    public void testCompleteLesson_NotFound_Returns404Envelope() throws Exception {
        doThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"))
                .when(progressService).completeLesson("user_123", "en_for_vi", "invalid_lesson");

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/invalid_lesson/complete")
                .header("Authorization", validToken)
                .header("X-Request-ID", "req_custom_123"))
                .andExpect(status().isNotFound())
                .andExpect(header().string("X-Request-ID", "req_custom_123"))
                .andExpect(jsonPath("$.error.code").value("LESSON_NOT_FOUND"))
                .andExpect(jsonPath("$.meta.requestId").value("req_custom_123"))
                .andExpect(jsonPath("$.meta.apiVersion").value("v1"))
                .andExpect(jsonPath("$.code").doesNotExist());
    }

    @Test
    public void testCompleteLesson_LessonIncomplete_Returns422Envelope() throws Exception {
        doThrow(new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Lesson questions not fully answered"))
                .when(progressService).completeLesson("user_123", "en_for_vi", "lesson_incomplete");

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_incomplete/complete")
                .header("Authorization", validToken))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.code").value("LESSON_INCOMPLETE"))
                .andExpect(jsonPath("$.meta.apiVersion").value("v1"))
                .andExpect(jsonPath("$.meta.requestId").exists())
                .andExpect(jsonPath("$.code").doesNotExist());
    }
}
