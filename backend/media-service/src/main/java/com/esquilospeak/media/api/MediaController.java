package com.esquilospeak.media.api;

import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.io.InputStream;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/media")
public class MediaController {

    private static final Set<String> ALLOWLIST = Set.of(
            "hello.mp3",
            "goodbye.mp3",
            "what_is_your_name.mp3",
            "five.mp3",
            "what_time_is_it.mp3",
            "hello_how_are_you.mp3"
    );

    @GetMapping("/{fileName}")
    public ResponseEntity<byte[]> getAudio(@PathVariable String fileName) {
        // 1. Path traversal protection & Allowlist validation
        if (fileName == null || fileName.contains("..") || fileName.contains("/") || fileName.contains("\\") || fileName.contains("%")) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        if (!ALLOWLIST.contains(fileName.toLowerCase())) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        try {
            ClassPathResource resource = new ClassPathResource("static/media/" + fileName);
            if (!resource.exists()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }

            long contentLength = resource.contentLength();
            byte[] bytes;
            try (InputStream is = resource.getInputStream()) {
                bytes = is.readAllBytes();
            }

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType("audio/mpeg"))
                    .header("Cache-Control", "public, max-age=86400")
                    .header("Content-Length", String.valueOf(contentLength))
                    .body(bytes);

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/metadata/{audioId}")
    public ResponseEntity<AudioMetadata> getMetadata(@PathVariable String audioId) {
        String baseName = audioId.endsWith(".mp3") ? audioId.replace(".mp3", "") : audioId;
        String fileName = baseName + ".mp3";

        if (!ALLOWLIST.contains(fileName)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        String transcript = switch (baseName) {
            case "hello" -> "Hello";
            case "goodbye" -> "Goodbye";
            case "what_is_your_name" -> "What is your name?";
            case "five" -> "Five";
            case "what_time_is_it" -> "What time is it?";
            case "hello_how_are_you" -> "Hello, how are you?";
            default -> "";
        };

        AudioMetadata metadata = new AudioMetadata(
                baseName,
                "en",
                "en-US",
                transcript,
                "media/" + fileName,
                1000,
                "v1"
        );

        return ResponseEntity.ok(metadata);
    }

    public static class AudioMetadata {
        private String audioId;
        private String targetLanguage;
        private String targetLocale;
        private String transcript;
        private String storageKey;
        private int durationMs;
        private String audioVersion;

        public AudioMetadata() {}

        public AudioMetadata(String audioId, String targetLanguage, String targetLocale, String transcript,
                             String storageKey, int durationMs, String audioVersion) {
            this.audioId = audioId;
            this.targetLanguage = targetLanguage;
            this.targetLocale = targetLocale;
            this.transcript = transcript;
            this.storageKey = storageKey;
            this.durationMs = durationMs;
            this.audioVersion = audioVersion;
        }

        public String getAudioId() { return audioId; }
        public String getTargetLanguage() { return targetLanguage; }
        public String getTargetLocale() { return targetLocale; }
        public String getTranscript() { return transcript; }
        public String getStorageKey() { return storageKey; }
        public int getDurationMs() { return durationMs; }
        public String getAudioVersion() { return audioVersion; }
    }
}
