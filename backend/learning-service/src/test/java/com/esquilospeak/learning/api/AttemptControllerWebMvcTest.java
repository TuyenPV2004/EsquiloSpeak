package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.service.AttemptSubmissionOperations;
import com.esquilospeak.learning.service.AttemptSubmissionService.AttemptSubmissionResult;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(value = AttemptController.class, properties = {
        "internal.service.token=esquilospeak_internal_s2s_token_for_testing_32_bytes_long"
})
public class AttemptControllerWebMvcTest {

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
    public void testSubmitAttempt_NoToken_Returns401() throws Exception {
        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(validAttempt("req_1"))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void testSubmitAttempt_HappyPath_ReturnsAttemptResponse() throws Exception {
        AttemptController.AttemptRequest request = validAttempt("req_1");
        when(attemptSubmissionService.submitOnlineAttempt(eq("user_123"), eq("en_for_vi"), any()))
                .thenReturn(AttemptSubmissionResult.success(
                        new AttemptController.AttemptResponse(true, "Xin chao", "Explanation vi", true),
                        false
                ));

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isCorrect").value(true))
                .andExpect(jsonPath("$.correctAnswer").value("Xin chao"))
                .andExpect(jsonPath("$.explanation").value("Explanation vi"))
                .andExpect(jsonPath("$.reviewCreated").value(true));
    }

    @Test
    public void testSubmitAttempt_MissingRequiredField_Returns400() throws Exception {
        AttemptController.AttemptRequest request = validAttempt("req_missing_field");
        request.setDeviceId(null);

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("INVALID_ATTEMPT_REQUEST"))
                .andExpect(jsonPath("$.meta.apiVersion").value("v1"))
                .andExpect(jsonPath("$.meta.requestId").exists())
                .andExpect(jsonPath("$.code").doesNotExist());

        verify(attemptSubmissionService, never()).submitOnlineAttempt(any(), any(), any());
    }

    @Test
    public void testSubmitAttempt_IdempotencyConflict_Returns409() throws Exception {
        AttemptController.AttemptRequest request = validAttempt("req_conflict");
        when(attemptSubmissionService.submitOnlineAttempt(eq("user_123"), eq("en_for_vi"), any()))
                .thenReturn(AttemptSubmissionResult.failed(
                        "IDEMPOTENCY_CONFLICT",
                        "clientRequestId was already used for a different attempt payload.",
                        HttpStatus.CONFLICT,
                        false
                ));

        mockMvc.perform(post("/api/v1/courses/en_for_vi/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error.code").value("IDEMPOTENCY_CONFLICT"))
                .andExpect(jsonPath("$.meta.apiVersion").value("v1"))
                .andExpect(jsonPath("$.meta.requestId").exists())
                .andExpect(jsonPath("$.code").doesNotExist());
    }

    private AttemptController.AttemptRequest validAttempt(String clientRequestId) {
        AttemptController.AttemptRequest request = new AttemptController.AttemptRequest();
        request.setClientRequestId(clientRequestId);
        request.setDeviceId("device_123");
        request.setCourseId("en_for_vi");
        request.setLessonId("lesson_1");
        request.setLessonVersionId("lesson_1_v1");
        request.setQuestionId("q_1");
        request.setQuestionVersionId("q_1_v1");
        request.setSelectedAnswer("Xin chao");
        request.setResponseTimeMs(2000);
        request.setAnsweredAt(LocalDateTime.parse("2026-06-23T10:00:00"));
        return request;
    }
}
