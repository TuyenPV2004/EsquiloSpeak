package com.esquilospeak.learning.api;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@RestControllerAdvice
public class ApiValidationExceptionHandler {

    private static final String REQUEST_ID_HEADER = "X-Request-ID";

    @ExceptionHandler({MethodArgumentNotValidException.class, MissingServletRequestParameterException.class, IllegalArgumentException.class})
    public ResponseEntity<ApiErrorResponse> handleBadRequestExceptions(Exception ex, HttpServletRequest request) {
        String requestId = extractOrGenerateRequestId(request);
        HttpHeaders headers = new HttpHeaders();
        headers.set(REQUEST_ID_HEADER, requestId);

        String errorCode = (ex instanceof MethodArgumentNotValidException) ? "INVALID_ATTEMPT_REQUEST" : "BAD_REQUEST";
        String message = ex.getMessage() != null ? ex.getMessage() : "Bad request parameters";

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .headers(headers)
                .body(ApiErrorResponse.of(errorCode, message, requestId));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiErrorResponse> handleResponseStatusException(ResponseStatusException ex, HttpServletRequest request) {
        String requestId = extractOrGenerateRequestId(request);
        HttpHeaders headers = new HttpHeaders();
        headers.set(REQUEST_ID_HEADER, requestId);

        String errorCode;
        if (ex.getStatusCode() == HttpStatus.NOT_FOUND) {
            errorCode = "LESSON_NOT_FOUND";
        } else if (ex.getStatusCode() == HttpStatus.CONFLICT) {
            errorCode = "EMPTY_LESSON";
        } else if (ex.getStatusCode() == HttpStatus.UNPROCESSABLE_ENTITY) {
            errorCode = "LESSON_INCOMPLETE";
        } else {
            errorCode = "GENERIC_ERROR";
        }

        String message = ex.getReason() != null ? ex.getReason() : ex.getMessage();
        return ResponseEntity.status(ex.getStatusCode())
                .headers(headers)
                .body(ApiErrorResponse.of(errorCode, message, requestId));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGeneralException(Exception ex, HttpServletRequest request) {
        String requestId = extractOrGenerateRequestId(request);
        HttpHeaders headers = new HttpHeaders();
        headers.set(REQUEST_ID_HEADER, requestId);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .headers(headers)
                .body(ApiErrorResponse.of("GENERIC_ERROR", ex.getMessage() != null ? ex.getMessage() : "An unexpected error occurred", requestId));
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
