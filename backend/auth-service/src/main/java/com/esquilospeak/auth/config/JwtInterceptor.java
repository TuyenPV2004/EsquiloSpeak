package com.esquilospeak.auth.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.util.UUID;

@Component
public class JwtInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // OPTIONS requests are allowed for CORS
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            sendErrorResponse(response, "UNAUTHORIZED", "Missing or invalid Authorization header");
            return false;
        }

        String token = authHeader.substring(7);
        if (!JwtTokenUtil.validateToken(token)) {
            sendErrorResponse(response, "UNAUTHORIZED", "Token validation failed");
            return false;
        }

        String userId = JwtTokenUtil.getUserIdFromToken(token);
        if (userId == null) {
            sendErrorResponse(response, "UNAUTHORIZED", "User ID not found in token");
            return false;
        }

        request.setAttribute("userId", userId);
        return true;
    }

    private void sendErrorResponse(HttpServletResponse response, String code, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String reqId = UUID.randomUUID().toString();
        String json = String.format(
            "{\"error\":{\"code\":\"%s\",\"message\":\"%s\",\"details\":{}},\"meta\":{\"requestId\":\"%s\",\"apiVersion\":\"v1\"}}",
            code, message, reqId
        );
        response.getWriter().write(json);
    }
}
