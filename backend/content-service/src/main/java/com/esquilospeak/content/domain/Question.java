package com.esquilospeak.content.domain;

import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "questions", schema = "content_schema")
public class Question {

    @Id
    @Column(name = "question_id", length = 50)
    private String questionId;

    @Column(name = "lesson_id", length = 50, nullable = false)
    private String lessonId;

    @Column(name = "prompt", nullable = false)
    private String prompt;

    @Column(name = "type", length = 50, nullable = false)
    private String type;

    @Column(name = "audio_url", length = 500)
    private String audioUrl;

    @Column(name = "correct_answer")
    private String correctAnswer;

    @Column(name = "explanation")
    private String explanation;

    @Column(name = "version_id", length = 50)
    private String versionId;

    @OneToMany(cascade = CascadeType.ALL, fetch = FetchType.EAGER, orphanRemoval = true)
    @JoinColumn(name = "question_id")
    private List<QuestionOption> options;

    public Question() {
    }

    public Question(String questionId, String lessonId, String prompt, String type, String audioUrl, 
                    String correctAnswer, String explanation, String versionId, List<QuestionOption> options) {
        this.questionId = questionId;
        this.lessonId = lessonId;
        this.prompt = prompt;
        this.type = type;
        this.audioUrl = audioUrl;
        this.correctAnswer = correctAnswer;
        this.explanation = explanation;
        this.versionId = versionId;
        this.options = options;
    }

    public String getQuestionId() { return questionId; }
    public void setQuestionId(String questionId) { this.questionId = questionId; }

    public String getLessonId() { return lessonId; }
    public void setLessonId(String lessonId) { this.lessonId = lessonId; }

    public String getPrompt() { return prompt; }
    public void setPrompt(String prompt) { this.prompt = prompt; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }

    public String getCorrectAnswer() { return correctAnswer; }
    public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = correctAnswer; }

    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }

    public String getVersionId() { return versionId; }
    public void setVersionId(String versionId) { this.versionId = versionId; }

    public List<QuestionOption> getOptions() { return options; }
    public void setOptions(List<QuestionOption> options) { this.options = options; }
}
