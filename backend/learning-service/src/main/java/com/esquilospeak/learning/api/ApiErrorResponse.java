package com.esquilospeak.learning.api;

public record ApiErrorResponse(ApiError error, ApiMeta meta) {
    public static final String API_VERSION = "v1";

    public static ApiErrorResponse of(String code, String message) {
        return of(code, message, null);
    }

    public static ApiErrorResponse of(String code, String message, String requestId) {
        String reqId = (requestId != null && !requestId.isBlank()) ? requestId : "req_" + java.util.UUID.randomUUID().toString().substring(0, 8);
        return new ApiErrorResponse(
                new ApiError(code, message),
                new ApiMeta(reqId, API_VERSION)
        );
    }

    public record ApiError(String code, String message) {}
    public record ApiMeta(String requestId, String apiVersion) {}
}
