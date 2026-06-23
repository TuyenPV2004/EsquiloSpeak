package com.esquilospeak.content.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "units", schema = "content_schema")
public class Unit {

    @Id
    @Column(name = "unit_id", length = 50)
    private String unitId;

    @Column(name = "course_id", length = 50, nullable = false)
    private String courseId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "sequence_order", nullable = false)
    private int sequenceOrder;

    public Unit() {
    }

    public Unit(String unitId, String courseId, String title, int sequenceOrder) {
        this.unitId = unitId;
        this.courseId = courseId;
        this.title = title;
        this.sequenceOrder = sequenceOrder;
    }

    public String getUnitId() { return unitId; }
    public void setUnitId(String unitId) { this.unitId = unitId; }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public int getSequenceOrder() { return sequenceOrder; }
    public void setSequenceOrder(int sequenceOrder) { this.sequenceOrder = sequenceOrder; }
}
