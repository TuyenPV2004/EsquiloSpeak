package com.esquilospeak.learning.client;

import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

@Service
public class ContentClientImpl implements ContentClient {

    @Value("${internal.service.token}")
    private String internalServiceToken;

    @Autowired
    private RestTemplate restTemplate;

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

    @Override
    public QuestionDto getQuestion(String questionId) {
        try {
            String url = "http://content-service/api/v1/internal/questions/" + questionId;
            ResponseEntity<QuestionDto> res = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    createInternalHeadersEntity(),
                    QuestionDto.class
            );
            return res.getBody();
        } catch (Exception e) {
            return null;
        }
    }

    @Override
    public List<String> getCourseLessons(String courseId) {
        try {
            String url = "http://content-service/api/v1/internal/courses/" + courseId + "/lessons";
            ResponseEntity<List<String>> res = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    createInternalHeadersEntity(),
                    new ParameterizedTypeReference<List<String>>() {}
            );
            return res.getBody() != null ? res.getBody() : new ArrayList<>();
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    @Override
    public List<String> getLessonQuestionIds(String courseId, String lessonId) {
        try {
            String url = "http://content-service/api/v1/internal/courses/" + courseId + "/lessons/" + lessonId + "/question-ids";
            ResponseEntity<List<String>> res = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    createInternalHeadersEntity(),
                    new ParameterizedTypeReference<List<String>>() {}
            );
            return res.getBody();
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            if (e.getStatusCode() == org.springframework.http.HttpStatus.NOT_FOUND) {
                return null;
            }
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch lesson question IDs via S2S", e);
        }
    }
}
