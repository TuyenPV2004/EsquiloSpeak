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

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import com.esquilospeak.learning.BaseIntegrationTest;
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
    private String userId = "user_sync_test";

    @BeforeEach
    public void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .addFilters(new JwtAuthenticationFilter())
                .build();
        validToken = "Bearer " + JwtTokenUtil.generateToken(userId, "device_123");
    }

    @Test
    public void testBatchSync_Integration() throws Exception {
        String clientReqNew = "req_" + UUID.randomUUID().toString();
        String clientReqDup = "req_" + UUID.randomUUID().toString();
        String clientReqStale = "req_" + UUID.randomUUID().toString();

        QuestionAttempt existing = new QuestionAttempt(
                "att_" + UUID.randomUUID().toString(),
                clientReqDup,
                userId,
                "course_1",
                "lesson_1",
                "q_dup",
                "q_dup_v1",
                "Xin chào",
                true,
                1500,
                LocalDateTime.now()
        );
        questionAttemptRepository.saveAndFlush(existing);

        AttemptController.QuestionDto qNew = new AttemptController.QuestionDto();
        qNew.setQuestionId("q_new");
        qNew.setCorrectAnswer("CorrectNew");
        qNew.setPrompt("New Prompt");
        qNew.setType("multiple_choice");
        qNew.setVersionId("q_new_v1");
        when(contentClient.getQuestion("q_new")).thenReturn(qNew);

        AttemptController.QuestionDto qStale = new AttemptController.QuestionDto();
        qStale.setQuestionId("q_stale");
        qStale.setCorrectAnswer("CorrectStale");
        qStale.setPrompt("Stale Prompt");
        qStale.setType("multiple_choice");
        qStale.setVersionId("q_stale_v2_new");
        when(contentClient.getQuestion("q_stale")).thenReturn(qStale);

        SyncController.SyncRequest request = new SyncController.SyncRequest();
        
        AttemptController.AttemptRequest attNew = new AttemptController.AttemptRequest();
        attNew.setClientRequestId(clientReqNew);
        attNew.setCourseId("course_1");
        attNew.setLessonId("lesson_1");
        attNew.setQuestionId("q_new");
        attNew.setQuestionVersionId("q_new_v1");
        attNew.setSelectedAnswer("CorrectNew");
        attNew.setResponseTimeMs(1500);

        AttemptController.AttemptRequest attDup = new AttemptController.AttemptRequest();
        attDup.setClientRequestId(clientReqDup);
        attDup.setCourseId("course_1");
        attDup.setLessonId("lesson_1");
        attDup.setQuestionId("q_dup");
        attDup.setQuestionVersionId("q_dup_v1");
        attDup.setSelectedAnswer("Xin chào");
        attDup.setResponseTimeMs(1000);

        AttemptController.AttemptRequest attStale = new AttemptController.AttemptRequest();
        attStale.setClientRequestId(clientReqStale);
        attStale.setCourseId("course_1");
        attStale.setLessonId("lesson_1");
        attStale.setQuestionId("q_stale");
        attStale.setQuestionVersionId("q_stale_v1_old");
        attStale.setSelectedAnswer("CorrectStale");
        attStale.setResponseTimeMs(2000);

        request.setAttempts(Arrays.asList(attNew, attDup, attStale));

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
}
