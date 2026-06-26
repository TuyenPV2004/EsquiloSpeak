package com.esquilospeak.content.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.io.Decoders;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

public class JwtTokenUtil {

    private static SecretKey signingKey;

    public static void setSecretKey(String secret) {
        byte[] keyBytes = Decoders.BASE64.decode(secret);
        if (keyBytes.length < 32) {
            throw new IllegalStateException("JWT Secret key must be at least 256 bits (32 bytes) long for HMAC-SHA256");
        }
        signingKey = Keys.hmacShaKeyFor(keyBytes);
    }

    private static SecretKey getSigningKey() {
        if (signingKey == null) {
            throw new IllegalStateException("JWT signing key has not been initialized");
        }
        return signingKey;
    }

    public static String getUserIdFromToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(cleanToken(token))
                    .getPayload();
            return claims.getSubject();
        } catch (Exception e) {
            return null;
        }
    }

    public static boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(cleanToken(token));
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static String cleanToken(String token) {
        if (token != null && token.startsWith("Bearer ")) {
            return token.substring(7);
        }
        return token;
    }

    @Component
    public static class JwtTokenInitializer {
        @Value("${spring.security.jwt.secret}")
        private String secret;

        @PostConstruct
        public void init() {
            if (secret == null || secret.trim().isEmpty()) {
                throw new IllegalStateException("spring.security.jwt.secret property must be set");
            }
            JwtTokenUtil.setSecretKey(secret);
        }
    }
}
