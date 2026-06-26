package com.esquilospeak.content.client;

import com.esquilospeak.content.exception.LearningServiceUnavailableException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

public class LearningServiceClientTest {

    private LearningServiceClient learningServiceClient;
    private MockRestServiceServer mockServer;

    @BeforeEach
    public void setUp() {
        learningServiceClient = new LearningServiceClient();
        RestTemplate restTemplate = new RestTemplate();
        mockServer = MockRestServiceServer.createServer(restTemplate);
        
        ReflectionTestUtils.setField(learningServiceClient, "restTemplate", restTemplate);
        ReflectionTestUtils.setField(learningServiceClient, "internalServiceToken", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long");
        ReflectionTestUtils.setField(learningServiceClient, "learningServiceBaseUrl", "http://learning-service:8080");
    }

    @Test
    public void testGetCompletedLessons_Success() {
        mockServer.expect(requestTo("http://learning-service:8080/api/v1/internal/users/user_123/completed-lessons"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long"))
                .andRespond(withSuccess("[\"lesson_1\", \"lesson_2\"]", MediaType.APPLICATION_JSON));

        Set<String> completed = learningServiceClient.getCompletedLessons("user_123");
        assertNotNull(completed);
        assertEquals(2, completed.size());
        assertTrue(completed.contains("lesson_1"));
        assertTrue(completed.contains("lesson_2"));
        mockServer.verify();
    }

    @Test
    public void testGetCompletedLessons_Error_ThrowsUnavailableException() {
        mockServer.expect(requestTo("http://learning-service:8080/api/v1/internal/users/user_123/completed-lessons"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withServerError());

        assertThrows(LearningServiceUnavailableException.class, () -> {
            learningServiceClient.getCompletedLessons("user_123");
        });
        mockServer.verify();
    }

    @Test
    public void testGetDueReviewCount_Success() {
        mockServer.expect(requestTo("http://learning-service:8080/api/v1/internal/courses/en_for_vi/reviews/due/count?userId=user_123"))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("X-Internal-Service-Token", "esquilospeak_internal_s2s_token_for_testing_32_bytes_long"))
                .andRespond(withSuccess("5", MediaType.APPLICATION_JSON));

        int count = learningServiceClient.getDueReviewCount("en_for_vi", "user_123");
        assertEquals(5, count);
        mockServer.verify();
    }

    @Test
    public void testGetDueReviewCount_Error_ReturnsZeroFallback() {
        mockServer.expect(requestTo("http://learning-service:8080/api/v1/internal/courses/en_for_vi/reviews/due/count?userId=user_123"))
                .andExpect(method(HttpMethod.GET))
                .andRespond(withServerError());

        int count = learningServiceClient.getDueReviewCount("en_for_vi", "user_123");
        assertEquals(0, count);
        mockServer.verify();
    }
}
