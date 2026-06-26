package com.esquilospeak.learning.config;

import jakarta.annotation.PostConstruct;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

@Component
public class InternalServiceAuthInterceptor implements HandlerInterceptor {

    @Value("${internal.service.token}")
    private String internalServiceToken;

    @PostConstruct
    public void validateInternalServiceToken() {
        if (internalServiceToken == null || internalServiceToken.trim().isEmpty()) {
            throw new IllegalStateException("INTERNAL_SERVICE_TOKEN must not be null or empty");
        }
        if (internalServiceToken.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("INTERNAL_SERVICE_TOKEN must be at least 32 bytes long");
        }
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String tokenHeader = request.getHeader("X-Internal-Service-Token");
        
        if (tokenHeader == null || tokenHeader.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            return false;
        }

        byte[] headerBytes = tokenHeader.getBytes(StandardCharsets.UTF_8);
        byte[] secretBytes = internalServiceToken.getBytes(StandardCharsets.UTF_8);

        if (MessageDigest.isEqual(headerBytes, secretBytes)) {
            return true;
        }

        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        return false;
    }
}
