package com.esquilospeak.learning.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String REQUEST_ID_HEADER = "X-Request-ID";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String path = request.getRequestURI();
        
        // We only authenticate public paths under /api/v1/courses/** and /api/v1/sync/**.
        // Internal S2S paths start with /api/v1/internal/** and do not require user JWT authentication.
        if ((path.startsWith("/api/v1/courses") || path.startsWith("/api/v1/sync")) 
                && !path.contains("/internal/")) {
            
            String authHeader = request.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                sendUnauthorized(request, response, "Missing or invalid Authorization header");
                return;
            }

            String token = authHeader.substring(7);
            if (!JwtTokenUtil.validateToken(token)) {
                sendUnauthorized(request, response, "Token is expired or invalid");
                return;
            }

            String userId = JwtTokenUtil.getUserIdFromToken(token);
            if (userId == null || userId.trim().isEmpty()) {
                sendUnauthorized(request, response, "User ID not found in token");
                return;
            }

            request.setAttribute("userId", userId);
        }

        filterChain.doFilter(request, response);
    }

    private void sendUnauthorized(HttpServletRequest request, HttpServletResponse response, String message) throws IOException {
        String requestId = extractOrGenerateRequestId(request);
        response.setHeader(REQUEST_ID_HEADER, requestId);
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(String.format(
                "{\"error\":{\"code\":\"UNAUTHORIZED\",\"message\":\"%s\"},\"meta\":{\"requestId\":\"%s\",\"apiVersion\":\"v1\"}}",
                message,
                requestId
        ));
    }

    private String extractOrGenerateRequestId(HttpServletRequest request) {
        if (request == null) {
            return "req_" + UUID.randomUUID().toString().substring(0, 8);
        }
        String header = request.getHeader(REQUEST_ID_HEADER);
        if (header == null || header.isBlank()) {
            header = request.getHeader("X-Correlation-ID");
        }
        if (header != null && !header.isBlank()) {
            return header;
        }
        return "req_" + UUID.randomUUID().toString().substring(0, 8);
    }
}
