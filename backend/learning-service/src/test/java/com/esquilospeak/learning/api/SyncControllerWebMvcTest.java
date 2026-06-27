package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.service.AttemptSubmissionOperations;
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

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(value = SyncController.class, properties = {
        "internal.service.token=esquilospeak_internal_s2s_token_for_testing_32_bytes_long"
})
public class SyncControllerWebMvcTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @MockBean
    private AttemptSubmissionOperations attemptSubmissionService;

    @Autowired
    private ObjectMapper objectMapper;

    private String validToken;

    @BeforeEach
    public void setUp() throws Exception {
        JwtTokenUtil.setSecretKey("ZXNxdWlsb3NwZWFrX3N1cGVyX3NlY3JldF9rZXlfZm9yX212cF90ZXN0aW5nXzEyMzQ1Njc4OTA=");

        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(new JwtAuthenticationFilter())
                .build();
        validToken = "Bearer " + JwtTokenUtil.generateToken("user_123", "device_123");
    }

    @Test
    public void testSyncAttempts_HappyPath_Synced() throws Exception {
        SyncController.SyncRequest request = syncRequest(validAttempt("req_sync_1", "q_1", "q_1_v1"));
        when(attemptSubmissionService.syncAttempt(eq("user_123"), any()))
                .thenReturn(new SyncController.SyncResult("req_sync_1", "SYNCED", null, null));

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.syncedCount").value(1))
                .andExpect(jsonPath("$.results[0].clientRequestId").value("req_sync_1"))
                .andExpect(jsonPath("$.results[0].status").value("SYNCED"));
    }

    @Test
    public void testSyncAttempts_EmptyAttempts_Returns400() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        request.setAttempts(Collections.emptyList());

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_ATTEMPT_REQUEST"))
                .andExpect(jsonPath("$.meta.apiVersion").value("v1"))
                .andExpect(jsonPath("$.meta.requestId").exists())
                .andExpect(jsonPath("$.code").doesNotExist());
    }

    @Test
    public void testSyncAttempts_ItemMissingField_ReturnsPerItemFailedAndContinues() throws Exception {
        AttemptController.AttemptRequest invalid = validAttempt("req_sync_invalid", "q_invalid", "q_invalid_v1");
        invalid.setDeviceId(null);
        AttemptController.AttemptRequest valid = validAttempt("req_sync_valid", "q_1", "q_1_v1");
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        request.setAttempts(Arrays.asList(invalid, valid));

        when(attemptSubmissionService.syncAttempt(eq("user_123"), any()))
                .thenReturn(new SyncController.SyncResult("req_sync_valid", "SYNCED", null, null));

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.results[0].clientRequestId").value("req_sync_invalid"))
                .andExpect(jsonPath("$.results[0].status").value("FAILED"))
                .andExpect(jsonPath("$.results[0].errorCode").value("INVALID_ATTEMPT_REQUEST"))
                .andExpect(jsonPath("$.results[1].clientRequestId").value("req_sync_valid"))
                .andExpect(jsonPath("$.results[1].status").value("SYNCED"));
    }

    @Test
    public void testSyncAttempts_DuplicateAndConflictResults() throws Exception {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        request.setAttempts(Arrays.asList(
                validAttempt("req_dup", "q_1", "q_1_v1"),
                validAttempt("req_conflict", "q_1", "q_1_v1")
        ));

        when(attemptSubmissionService.syncAttempt(eq("user_123"), any()))
                .thenReturn(new SyncController.SyncResult("req_dup", "DUPLICATE", null, null))
                .thenReturn(new SyncController.SyncResult(
                        "req_conflict",
                        "FAILED",
                        "IDEMPOTENCY_CONFLICT",
                        "clientRequestId was already used for a different attempt payload."
                ));

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.syncedCount").value(0))
                .andExpect(jsonPath("$.results[0].status").value("DUPLICATE"))
                .andExpect(jsonPath("$.results[1].errorCode").value("IDEMPOTENCY_CONFLICT"));
    }

    @Test
    public void testSyncAttempts_UnexpectedException_ReturnsRetryableFailedAndContinuesBatch() throws Exception {
        AttemptController.AttemptRequest retryable = validAttempt("req_retryable", "q_1", "q_1_v1");
        AttemptController.AttemptRequest valid = validAttempt("req_sync_valid_after_error", "q_2", "q_2_v1");
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        request.setAttempts(Arrays.asList(retryable, valid));

        doThrow(new RuntimeException("content-service timeout"))
                .doReturn(new SyncController.SyncResult("req_sync_valid_after_error", "SYNCED", null, null))
                .when(attemptSubmissionService).syncAttempt(eq("user_123"), any());

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.syncedCount").value(1))
                .andExpect(jsonPath("$.results[0].clientRequestId").value("req_retryable"))
                .andExpect(jsonPath("$.results[0].status").value("RETRYABLE_FAILED"))
                .andExpect(jsonPath("$.results[0].errorCode").value("UNKNOWN_ERROR"))
                .andExpect(jsonPath("$.results[1].clientRequestId").value("req_sync_valid_after_error"))
                .andExpect(jsonPath("$.results[1].status").value("SYNCED"));
    }

    private SyncController.SyncRequest syncRequest(AttemptController.AttemptRequest attempt) {
        SyncController.SyncRequest request = new SyncController.SyncRequest();
        request.setAttempts(Collections.singletonList(attempt));
        return request;
    }

    private AttemptController.AttemptRequest validAttempt(String clientRequestId, String questionId, String questionVersionId) {
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId(clientRequestId);
        attempt.setDeviceId("device_123");
        attempt.setCourseId("en_for_vi");
        attempt.setLessonId("lesson_1");
        attempt.setLessonVersionId("lesson_1_v1");
        attempt.setQuestionId(questionId);
        attempt.setQuestionVersionId(questionVersionId);
        attempt.setSelectedAnswer("Xin chao");
        attempt.setResponseTimeMs(2000);
        attempt.setAnsweredAt(LocalDateTime.parse("2026-06-23T10:00:00"));
        return attempt;
    }
}
