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
import java.util.Collections;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SyncController.class)
public class SyncControllerWebMvcTest {

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
    public void testSyncAttempts_HappyPath_Synced() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_1");
        attempt.setQuestionId("q_1");
        attempt.setQuestionVersionId("q_1_v1");
        attempt.setSelectedAnswer("Xin chào");
        attempt.setResponseTimeMs(2000);
        request.setAttempts(Collections.singletonList(attempt));

        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Xin chào");
        question.setPrompt("Hello");
        question.setType("multiple_choice");
        question.setVersionId("q_1_v1");

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_1")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_1")).thenReturn(question);

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.results[0].clientRequestId").value("req_sync_1"))
                .andExpect(jsonPath("$.results[0].status").value("SYNCED"));

        verify(questionAttemptRepository, times(1)).save(any(QuestionAttempt.class));
    }

    @Test
    public void testSyncAttempts_DuplicateRequestId_ReturnsDuplicate() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_duplicate");
        attempt.setQuestionId("q_1");
        request.setAttempts(Collections.singletonList(attempt));

        QuestionAttempt existingAttempt = new QuestionAttempt();
        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_duplicate")).thenReturn(Optional.of(existingAttempt));

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("DUPLICATE"));

        verify(questionAttemptRepository, never()).save(any(QuestionAttempt.class));
    }

    @Test
    public void testSyncAttempts_StaleVersion_ReturnsStaleContent() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_stale");
        attempt.setQuestionId("q_1");
        attempt.setQuestionVersionId("q_1_v1_old");
        attempt.setSelectedAnswer("Xin chào");
        request.setAttempts(Collections.singletonList(attempt));

        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Xin chào");
        question.setVersionId("q_1_v1_new");

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_stale")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_1")).thenReturn(question);

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("FAILED"))
                .andExpect(jsonPath("$.results[0].errorCode").value("STALE_CONTENT"));

        verify(questionAttemptRepository, never()).save(any(QuestionAttempt.class));
    }

    @Test
    public void testSyncAttempts_MissingQuestionVersion_ReturnsFailed() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_missing_version");
        attempt.setQuestionId("q_1");
        attempt.setQuestionVersionId(""); // Rỗng
        attempt.setSelectedAnswer("Xin chào");
        request.setAttempts(Collections.singletonList(attempt));

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_missing_version")).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("FAILED"))
                .andExpect(jsonPath("$.results[0].errorCode").value("MISSING_QUESTION_VERSION"));

        verify(questionAttemptRepository, never()).save(any(QuestionAttempt.class));
    }

    @Test
    public void testSyncAttempts_ServerVersionMissing_ReturnsRetryableFailed() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_server_missing");
        attempt.setQuestionId("q_1");
        attempt.setQuestionVersionId("q_1_v1");
        attempt.setSelectedAnswer("Xin chào");
        request.setAttempts(Collections.singletonList(attempt));

        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId("q_1");
        question.setCorrectAnswer("Xin chào");
        question.setVersionId(""); // Server thiếu version

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_server_missing")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_1")).thenReturn(question);

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("RETRYABLE_FAILED"))
                .andExpect(jsonPath("$.results[0].errorCode").value("QUESTION_VERSION_MISSING"));

        verify(questionAttemptRepository, never()).save(any(QuestionAttempt.class));
    }

    @Test
    public void testSyncAttempts_QuestionNotFound_ReturnsFailed() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_not_found");
        attempt.setQuestionId("q_notFound");
        attempt.setQuestionVersionId("v1");
        request.setAttempts(Collections.singletonList(attempt));

        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_not_found")).thenReturn(Optional.empty());
        when(contentClient.getQuestion("q_notFound")).thenReturn(null);

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("FAILED"))
                .andExpect(jsonPath("$.results[0].errorCode").value("QUESTION_NOT_FOUND"));
    }

    @Test
    public void testSyncAttempts_DuplicateClientRequestId_DoesNotCheckStaleVersion() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId("req_sync_duplicate_check");
        attempt.setQuestionId("q_1");
        attempt.setQuestionVersionId("q_1_v_old");
        request.setAttempts(Collections.singletonList(attempt));

        QuestionAttempt existingAttempt = new QuestionAttempt();
        when(questionAttemptRepository.findByUserIdAndClientRequestId("user_123", "req_sync_duplicate_check")).thenReturn(Optional.of(existingAttempt));

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].status").value("DUPLICATE"));

        verify(contentClient, never()).getQuestion(any());
        verify(questionAttemptRepository, never()).save(any(QuestionAttempt.class));
    }
}
