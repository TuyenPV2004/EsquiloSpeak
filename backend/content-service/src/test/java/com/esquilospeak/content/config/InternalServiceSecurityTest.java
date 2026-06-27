package com.esquilospeak.content.config;

import com.esquilospeak.content.api.ContentController;
import com.esquilospeak.content.domain.Question;
import com.esquilospeak.content.infrastructure.QuestionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.Optional;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class InternalServiceSecurityTest {

    private MockMvc mockMvc;
    private QuestionRepository questionRepository;

    @BeforeEach
    public void setUp() {
        ContentController contentController = new ContentController();
        questionRepository = mock(QuestionRepository.class);
        ReflectionTestUtils.setField(contentController, "questionRepository", questionRepository);

        InternalServiceAuthInterceptor interceptor = new InternalServiceAuthInterceptor();
        ReflectionTestUtils.setField(
                interceptor,
                "internalServiceToken",
                "esquilospeak_internal_s2s_token_for_testing_32_bytes_long"
        );
        interceptor.validateInternalServiceToken();

        mockMvc = MockMvcBuilders
                .standaloneSetup(contentController)
                .addInterceptors(interceptor)
                .build();
    }

    @Test
    public void internalEndpoint_WithoutToken_Returns403() throws Exception {
        mockMvc.perform(get("/api/v1/internal/questions/q_1"))
                .andExpect(status().isForbidden());
    }

    @Test
    public void internalEndpoint_WithInvalidToken_Returns403() throws Exception {
        mockMvc.perform(get("/api/v1/internal/questions/q_1")
                .header("X-Internal-Service-Token", "invalid_token_123456789012345678901234567890"))
                .andExpect(status().isForbidden());
    }

    @Test
    public void internalEndpoint_WithValidToken_Returns200() throws Exception {
        Question question = new Question(
                "q_1",
                "lesson_1",
                "Prompt",
                "multiple_choice",
                null,
                "Correct",
                "Explanation",
                "q_1_v1",
                List.of()
        );
        when(questionRepository.findById("q_1")).thenReturn(Optional.of(question));

        mockMvc.perform(get("/api/v1/internal/questions/q_1")
                .header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long"))
                .andExpect(status().isOk());
    }
}
