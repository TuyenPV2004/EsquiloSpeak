package com.esquilospeak.content.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "lessons", schema = "content_schema")
public class Lesson {

    @Id
    @Column(name = "lesson_id", length = 50)
    private String lessonId;

    @Column(name = "unit_id", length = 50, nullable = false)
    private String unitId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "sequence_order", nullable = false)
    private int sequenceOrder;

    @Column(name = "version_id", length = 50)
    private String versionId;

    public Lesson() {
    }

    public Lesson(String lessonId, String unitId, String title, int sequenceOrder, String versionId) {
        this.lessonId = lessonId;
        this.unitId = unitId;
        this.title = title;
        this.sequenceOrder = sequenceOrder;
        this.versionId = versionId;
    }

    public String getLessonId() { return lessonId; }
    public void setLessonId(String lessonId) { this.lessonId = lessonId; }

    public String getUnitId() { return unitId; }
    public void setUnitId(String unitId) { this.unitId = unitId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public int getSequenceOrder() { return sequenceOrder; }
    public void setSequenceOrder(int sequenceOrder) { this.sequenceOrder = sequenceOrder; }

    public String getVersionId() { return versionId; }
    public void setVersionId(String versionId) { this.versionId = versionId; }
}
