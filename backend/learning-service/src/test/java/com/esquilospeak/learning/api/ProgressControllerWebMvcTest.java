package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.LessonProgress;
import com.esquilospeak.learning.infrastructure.LessonProgressRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.esquilospeak.learning.client.ContentClient;
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

    private String validToken;

    @BeforeEach
    public void setUp() {
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
        when(lessonProgressRepository.findByUserId("user_123")).thenReturn(Collections.emptyList());

        mockMvc.perform(post("/api/v1/courses/en_for_vi/lessons/lesson_1/complete")
                .header("Authorization", validToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(lessonProgressRepository, times(1)).save(any(LessonProgress.class));
    }
}
