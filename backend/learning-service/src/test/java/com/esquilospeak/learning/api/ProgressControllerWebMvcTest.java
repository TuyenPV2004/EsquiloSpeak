package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.config.InternalServiceAuthInterceptor;
import com.esquilospeak.learning.domain.LessonProgress;
import com.esquilospeak.learning.infrastructure.LessonProgressRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.esquilospeak.learning.client.ContentClient;
import com.esquilospeak.learning.service.ProgressService;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
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

import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProgressController.class)
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

    @MockBean
    private InternalServiceAuthInterceptor internalServiceAuthInterceptor;

    private String validToken;

    @BeforeEach
    public void setUp() throws Exception {
        JwtTokenUtil.setSecretKey("ZXNxdWlsb3NwZWFrX3N1cGVyX3NlY3JldF9rZXlfZm9yX212cF90ZXN0aW5nXzEyMzQ1Njc4OTA=");
        
        when(internalServiceAuthInterceptor.preHandle(any(), any(), any())).thenReturn(true);

        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(new JwtAuthenticationFilter())
                .build();
        validToken = "Bearer " + JwtTokenUtil.generateToken("user_123", "device_123");
    }

    @Test
    public void testCompleteLesson_NoToken_Returns401() throws Exception {
        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void testCompleteLesson_HappyPath() throws Exception {
        when(progressService.completeLesson(anyString(), anyString(), anyString())).thenReturn(null);

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete")
                .header("Authorization", validToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(progressService, times(1)).completeLesson("user_123", "en_for_vi", "lesson_1");
    }

    @Test
    public void testCompleteLesson_NotFound_Returns404() throws Exception {
        doThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson or course not found"))
                .when(progressService).completeLesson(anyString(), anyString(), anyString());

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete")
                .header("Authorization", validToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("LESSON_NOT_FOUND"));
    }

    @Test
    public void testCompleteLesson_EmptyLesson_Returns409() throws Exception {
        doThrow(new ResponseStatusException(HttpStatus.CONFLICT, "Lesson contains no questions"))
                .when(progressService).completeLesson(anyString(), anyString(), anyString());

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete")
                .header("Authorization", validToken))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error.code").value("EMPTY_LESSON"));
    }

    @Test
    public void testCompleteLesson_Incomplete_Returns422() throws Exception {
        doThrow(new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Not all questions answered correctly"))
                .when(progressService).completeLesson(anyString(), anyString(), anyString());

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete")
                .header("Authorization", validToken))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error.code").value("LESSON_INCOMPLETE"));
    }
}
