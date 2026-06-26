package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.config.InternalServiceAuthInterceptor;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.service.ReviewItemService;
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
    private ReviewItemService reviewItemService;

    @MockBean
    private ContentClient contentClient;

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
        
        when(internalServiceAuthInterceptor.preHandle(any(), any(), any())).thenReturn(true);

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

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_1")).thenReturn(Optional.empty());
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

    @Test
    public void testSubmitAttempt_MissingQuestionVersion_Returns400() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_missing_version");
        request.setQuestionId("q_1");
        request.setSelectedAnswer("Xin chào");
        request.setQuestionVersionId(""); // Rỗng

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_missing_version")).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("MISSING_QUESTION_VERSION"));

        verify(questionAttemptRepository, never()).save(any());
    }

    @Test
    public void testSubmitAttempt_StaleVersion_Returns400() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_stale");
        request.setQuestionId("q_1");
        request.setSelectedAnswer("Xin chào");
        request.setQuestionVersionId("q_1_v_old"); // Version cũ

        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Xin chào");
        question.setVersionId("q_1_v_new"); // Version mới trên server

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_stale")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_1")).thenReturn(question);

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("STALE_CONTENT"));

        verify(questionAttemptRepository, never()).save(any());
    }

    @Test
    public void testSubmitAttempt_MissingServerVersion_Returns500() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_server_missing");
        request.setQuestionId("q_1");
        request.setSelectedAnswer("Xin chào");
        request.setQuestionVersionId("q_1_v1");

        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Xin chào");
        question.setVersionId(""); // Server thiếu version

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_server_missing")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_1")).thenReturn(question);

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error.code").value("QUESTION_VERSION_MISSING"));

        verify(questionAttemptRepository, never()).save(any());
    }

    @Test
    public void testSubmitAttempt_QuestionNotFound_Returns400() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_not_found");
        request.setQuestionId("q_notFound");
        request.setQuestionVersionId("v1");

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_not_found")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_notFound")).thenReturn(null);

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("QUESTION_NOT_FOUND"));
    }

    @Test
    public void testSubmitAttempt_DuplicateClientRequestId_DoesNotCheckStaleVersion() throws Exception {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId("req_duplicate");
        request.setQuestionId("q_1");
        request.setQuestionVersionId("q_1_v_any");

        QuestionAttempt existingAttempt = new QuestionAttempt(
                "att_123",
                "req_duplicate",
                "user_123",
                "en_for_vi",
                "lesson_1",
                "q_1",
                "q_1_v1",
                "selected",
                true,
                1000,
                java.time.LocalDateTime.now()
        );

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_duplicate")).thenReturn(Optional.of(existingAttempt));

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isCorrect").value(true))
                .andExpect(jsonPath("$.correctAnswer").value(""))
                .andExpect(jsonPath("$.explanation").value(""));

        verify(contentClient, never()).getQuestion(any());
        verify(questionAttemptRepository, never()).save(any());
    }
}
