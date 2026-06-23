package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
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

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AttemptController.class)
public class AttemptControllerWebMvcTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @MockBean
    private QuestionAttemptRepository questionAttemptRepository;

    @MockBean
    private ReviewItemRepository reviewItemRepository;

    @MockBean
    private ContentClient contentClient;

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
    public void testSubmitAttempt_NoToken_Returns401() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_1");
        request.setQuestionId("q_1");

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void testSubmitAttempt_InvalidToken_Returns401() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_1");
        request.setQuestionId("q_1");

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", "Bearer invalid_token_123")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void testSubmitAttempt_HappyPath_CorrectAnswer() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_1");
        request.setQuestionId("q_1");
        request.setSelectedAnswer("Xin chào");
        request.setResponseTimeMs(2000);
        request.setQuestionVersionId("q_1_v1");

        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Xin chào");
        question.setExplanation("Explanation vi");
        question.setPrompt("Hello");
        question.setType("multiple_choice");
        question.setVersionId("q_1_v1");

        when(questionAttemptRepository.findByClientRequestId("req_1")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_1")).thenReturn(question);

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isCorrect").value(true))
                .andExpect(jsonPath("$.correctAnswer").value("Xin chào"))
                .andExpect(jsonPath("$.explanation").value("Explanation vi"));

        verify(questionAttemptRepository, times(1)).save(argThat(attempt -> 
            "q_1_v1".equals(attempt.getQuestionVersionId())
        ));
    }
}
