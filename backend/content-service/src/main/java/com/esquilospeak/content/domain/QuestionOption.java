package com.esquilospeak.content.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "question_options", schema = "content_schema")
public class QuestionOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "option_id")
    private Long optionId;

    @Column(name = "option_text", nullable = false)
    private String optionText;

    public QuestionOption() {
    }

    public QuestionOption(String optionText) {
        this.optionText = optionText;
    }

    public Long getOptionId() { return optionId; }
    public void setOptionId(Long optionId) { this.optionId = optionId; }

    public String getOptionText() { return optionText; }
    public void setOptionText(String optionText) { this.optionText = optionText; }
}
