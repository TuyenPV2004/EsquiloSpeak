package com.esquilospeak.learning.config;

import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class JwtTokenUtil {

    private static final String SECRET_KEY = "esquilospeak_super_secret_key_for_mvp_testing";
    private static final String HEADER_JSON = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";

    public static String generateToken(String userId, String deviceId) {
        try {
            String header = Base64.getUrlEncoder().withoutPadding().encodeToString(HEADER_JSON.getBytes(StandardCharsets.UTF_8));
            String payloadJson = String.format("{\"userId\":\"%s\",\"deviceId\":\"%s\"}", userId, deviceId);
            String payload = Base64.getUrlEncoder().withoutPadding().encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));

            String signature = sign(header + "." + payload, SECRET_KEY);
            return header + "." + payload + "." + signature;
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate JWT", e);
        }
    }

    public static String getUserIdFromToken(String token) {
        String payload = getPayloadFromToken(token);
        if (payload == null) return null;
        return extractJsonField(payload, "userId");
    }

    public static String getDeviceIdFromToken(String token) {
        String payload = getPayloadFromToken(token);
        if (payload == null) return null;
        return extractJsonField(payload, "deviceId");
    }

    public static boolean validateToken(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                return false;
            }
            String calculatedSignature = sign(parts[0] + "." + parts[1], SECRET_KEY);
            return calculatedSignature.equals(parts[2]);
        } catch (Exception e) {
            return false;
        }
    }

    private static String getPayloadFromToken(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length < 2) return null;
            byte[] decodedBytes = Base64.getUrlDecoder().decode(parts[1]);
            return new String(decodedBytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            return null;
        }
    }

    private static String sign(String data, String secret) throws NoSuchAlgorithmException, InvalidKeyException {
        Mac sha256HMAC = Mac.getInstance("HmacSHA256");
        SecretKeySpec secretKey = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        sha256HMAC.init(secretKey);
        byte[] hash = sha256HMAC.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
    }

    private static String extractJsonField(String json, String field) {
        Pattern pattern = Pattern.compile("\"" + field + "\":\"([^\"]+)\"");
        Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }
}
