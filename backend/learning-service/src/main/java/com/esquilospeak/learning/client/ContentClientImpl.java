package com.esquilospeak.learning.client;

import com.esquilospeak.learning.api.AttemptController.QuestionDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

@Service
public class ContentClientImpl implements ContentClient {

    @Autowired
    private RestTemplate restTemplate;

    @Override
    public QuestionDto getQuestion(String questionId) {
        try {
            String url = "http://content-service/api/v1/internal/questions/" + questionId;
            return restTemplate.getForObject(url, QuestionDto.class);
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
                    null,
                    new ParameterizedTypeReference<List<String>>() {}
            );
            return res.getBody() != null ? res.getBody() : new ArrayList<>();
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }
}
