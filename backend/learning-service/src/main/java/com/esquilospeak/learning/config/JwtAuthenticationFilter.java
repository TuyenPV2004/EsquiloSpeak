package com.esquilospeak.learning.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

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
                sendUnauthorized(response, "Missing or invalid Authorization header");
                return;
            }

            String token = authHeader.substring(7);
            if (!JwtTokenUtil.validateToken(token)) {
                sendUnauthorized(response, "Token is expired or invalid");
                return;
            }

            String userId = JwtTokenUtil.getUserIdFromToken(token);
            if (userId == null || userId.trim().isEmpty()) {
                sendUnauthorized(response, "User ID not found in token");
                return;
            }

            request.setAttribute("userId", userId);
        }

        filterChain.doFilter(request, response);
    }

    private void sendUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(String.format(
                "{\"error\":{\"code\":\"UNAUTHORIZED\",\"message\":\"%s\"},\"meta\":{\"apiVersion\":\"v1\"}}",
                message
        ));
    }
}
