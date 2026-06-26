package com.esquilospeak.content.exception;

public class LearningServiceUnavailableException extends RuntimeException {
    public LearningServiceUnavailableException(String message) {
        super(message);
    }
    public LearningServiceUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
