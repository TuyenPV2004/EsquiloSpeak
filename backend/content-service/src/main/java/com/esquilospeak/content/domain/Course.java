package com.esquilospeak.content.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "courses", schema = "content_schema")
public class Course {

    @Id
    @Column(name = "course_id", length = 50)
    private String courseId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "source_language", length = 10, nullable = false)
    private String sourceLanguage;

    @Column(name = "target_language", length = 10, nullable = false)
    private String targetLanguage;

    @Column(name = "level", length = 10)
    private String level;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public Course() {
    }

    public Course(String courseId, String title, String sourceLanguage, String targetLanguage, String level, LocalDateTime createdAt) {
        this.courseId = courseId;
        this.title = title;
        this.sourceLanguage = sourceLanguage;
        this.targetLanguage = targetLanguage;
        this.level = level;
        this.createdAt = createdAt;
    }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getSourceLanguage() { return sourceLanguage; }
    public void setSourceLanguage(String sourceLanguage) { this.sourceLanguage = sourceLanguage; }

    public String getTargetLanguage() { return targetLanguage; }
    public void setTargetLanguage(String targetLanguage) { this.targetLanguage = targetLanguage; }

    public String getLevel() { return level; }
    public void setLevel(String level) { this.level = level; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
