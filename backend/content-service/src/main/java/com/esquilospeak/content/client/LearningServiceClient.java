package com.esquilospeak.content.client;

import com.esquilospeak.content.exception.LearningServiceUnavailableException;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class LearningServiceClient {

    @Autowired
    private RestTemplate restTemplate;

    @Value("${internal.service.token}")
    private String internalServiceToken;

    @Value("${services.learning.base-url:http://learning-service}")
    private String learningServiceBaseUrl;

    @PostConstruct
    public void validateInternalServiceToken() {
        if (internalServiceToken == null || internalServiceToken.trim().isEmpty()) {
            throw new IllegalStateException("INTERNAL_SERVICE_TOKEN must not be null or empty");
        }
        if (internalServiceToken.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("INTERNAL_SERVICE_TOKEN must be at least 32 bytes long");
        }
    }

    private HttpEntity<Void> createInternalHeadersEntity() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-Internal-Service-Token", internalServiceToken);
        return new HttpEntity<>(headers);
    }

    public Set<String> getCompletedLessons(String userId) {
        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(learningServiceBaseUrl)
                    .path("/api/v1/internal/users/{userId}/completed-lessons")
                    .buildAndExpand(userId)
                    .toUriString();

            ResponseEntity<List> res = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    createInternalHeadersEntity(),
                    List.class
            );

            if (res.getStatusCode().isError() || res.getBody() == null) {
                throw new LearningServiceUnavailableException("Learning service returned error code or empty response");
            }

            Set<String> completedLessonIds = new HashSet<>();
            for (Object obj : res.getBody()) {
                completedLessonIds.add(obj.toString());
            }
            return completedLessonIds;
        } catch (RestClientException e) {
            throw new LearningServiceUnavailableException("Failed to call learning-service completed-lessons", e);
        }
    }

    public int getDueReviewCount(String courseId, String userId) {
        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(learningServiceBaseUrl)
                    .path("/api/v1/internal/courses/{courseId}/reviews/due/count")
                    .queryParam("userId", userId)
                    .buildAndExpand(courseId)
                    .toUriString();

            ResponseEntity<Integer> res = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    createInternalHeadersEntity(),
                    Integer.class
            );

            if (res.getBody() != null) {
                return res.getBody();
            }
        } catch (Exception e) {
            // fallback gracefully to 0
        }
        return 0;
    }
}
