package com.esquilospeak.learning.api;

import com.esquilospeak.learning.BaseIntegrationTest;
import com.esquilospeak.learning.client.ContentClient;
import com.esquilospeak.learning.config.JwtAuthenticationFilter;
import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Transactional
public class SyncAttemptsIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @MockBean
    private ContentClient contentClient;

    @Autowired
    private ObjectMapper objectMapper;

    private String validToken;
    private final String userId = "user_sync_test";

    @BeforeEach
    public void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(new JwtAuthenticationFilter())
                .build();
        validToken = "Bearer " + JwtTokenUtil.generateToken(userId, "device_123");
    }

    @Test
    public void testBatchSync_Integration() throws Exception {
        String clientReqNew = "req_" + UUID.randomUUID();
        String clientReqDup = "req_" + UUID.randomUUID();
        String clientReqStale = "req_" + UUID.randomUUID();

        QuestionAttempt existing = new QuestionAttempt(
                "att_" + UUID.randomUUID(),
                clientReqDup,
                userId,
                "course_1",
                "lesson_1",
                "q_dup",
                "q_dup_v1",
                "Hello",
                true,
                1500,
                LocalDateTime.parse("2026-06-23T10:00:00")
        );
        questionAttemptRepository.saveAndFlush(existing);

        when(contentClient.getLessonQuestionIds("course_1", "lesson_1")).thenReturn(Arrays.asList("q_new", "q_dup", "q_stale"));
        when(contentClient.getQuestion("q_new")).thenReturn(question("q_new", "q_new_v1", "CorrectNew"));
        when(contentClient.getQuestion("q_stale")).thenReturn(question("q_stale", "q_stale_v2_new", "CorrectStale"));

        SyncController.SyncRequest request = new SyncController.SyncRequest();
        request.setAttempts(Arrays.asList(
                attempt(clientReqNew, "q_new", "q_new_v1", "CorrectNew"),
                attempt(clientReqDup, "q_dup", "q_dup_v1", "Hello"),
                attempt(clientReqStale, "q_stale", "q_stale_v1_old", "CorrectStale")
        ));

        mockMvc.perform(post("/api/v1/sync/attempts")
                .header("Authorization", validToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.results[0].clientRequestId").value(clientReqNew))
                .andExpect(jsonPath("$.results[0].status").value("SYNCED"))
                .andExpect(jsonPath("$.results[1].clientRequestId").value(clientReqDup))
                .andExpect(jsonPath("$.results[1].status").value("DUPLICATE"))
                .andExpect(jsonPath("$.results[2].clientRequestId").value(clientReqStale))
                .andExpect(jsonPath("$.results[2].status").value("FAILED"))
                .andExpect(jsonPath("$.results[2].errorCode").value("STALE_CONTENT"));

        Optional<QuestionAttempt> savedNew = questionAttemptRepository.findByUserIdAndClientRequestId(userId, clientReqNew);
        assertTrue(savedNew.isPresent());
        assertEquals("q_new_v1", savedNew.get().getQuestionVersionId());

        Optional<QuestionAttempt> savedStale = questionAttemptRepository.findByUserIdAndClientRequestId(userId, clientReqStale);
        assertFalse(savedStale.isPresent());
    }

    private AttemptController.AttemptRequest attempt(String clientRequestId, String questionId, String questionVersionId, String selectedAnswer) {
        AttemptController.AttemptRequest attempt = new AttemptController.AttemptRequest();
        attempt.setClientRequestId(clientRequestId);
        attempt.setDeviceId("device_123");
        attempt.setCourseId("course_1");
        attempt.setLessonId("lesson_1");
        attempt.setLessonVersionId("lesson_1_v1");
        attempt.setQuestionId(questionId);
        attempt.setQuestionVersionId(questionVersionId);
        attempt.setSelectedAnswer(selectedAnswer);
        attempt.setResponseTimeMs(1500);
        attempt.setAnsweredAt(LocalDateTime.parse("2026-06-23T10:00:00"));
        return attempt;
    }

    private AttemptController.QuestionDto question(String questionId, String versionId, String correctAnswer) {
        AttemptController.QuestionDto question = new AttemptController.QuestionDto();
        question.setQuestionId(questionId);
        question.setCorrectAnswer(correctAnswer);
        question.setPrompt("Prompt");
        question.setType("multiple_choice");
        question.setVersionId(versionId);
        return question;
    }
}
