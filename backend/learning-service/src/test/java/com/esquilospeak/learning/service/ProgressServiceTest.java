package com.esquilospeak.learning.service;

import com.esquilospeak.learning.client.ContentClient;
import com.esquilospeak.learning.domain.LessonProgress;
import com.esquilospeak.learning.infrastructure.LessonProgressRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class ProgressServiceTest {

    @Mock
    private LessonProgressRepository lessonProgressRepository;

    @Mock
    private QuestionAttemptRepository questionAttemptRepository;

    @Mock
    private ContentClient contentClient;

    @InjectMocks
    private ProgressService progressService;

    @Test
    public void completeLesson_WhenNotAllRealLessonQuestionsCorrect_Returns422AndDoesNotSaveProgress() {
        when(lessonProgressRepository.findByUserIdAndLessonIdAndStatus("user_123", "lesson_1", "COMPLETED"))
                .thenReturn(Optional.empty());
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1"))
                .thenReturn(List.of("q_1", "q_2"));
        when(questionAttemptRepository.countCorrectQuestions(
                eq("user_123"),
                eq("course_1"),
                eq("lesson_1"),
                anyList()))
                .thenReturn(1L);

        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> progressService.completeLesson("user_123", "course_1", "lesson_1"));

        assertEquals(HttpStatus.UNPROCESSABLE_ENTITY, ex.getStatusCode());
        verify(lessonProgressRepository, never()).save(any());
        ArgumentCaptor<List<String>> questionIdsCaptor = ArgumentCaptor.forClass(List.class);
        verify(questionAttemptRepository).countCorrectQuestions(
                eq("user_123"),
                eq("course_1"),
                eq("lesson_1"),
                questionIdsCaptor.capture());
        assertEquals(Set.of("q_1", "q_2"), Set.copyOf(questionIdsCaptor.getValue()));
    }

    @Test
    public void completeLesson_WhenAllRealLessonQuestionsCorrect_SavesCompletedProgress() {
        when(lessonProgressRepository.findByUserIdAndLessonIdAndStatus("user_123", "lesson_1", "COMPLETED"))
                .thenReturn(Optional.empty());
        when(contentClient.getLessonQuestionIds("course_1", "lesson_1"))
                .thenReturn(List.of("q_1", "q_2"));
        when(questionAttemptRepository.countCorrectQuestions(
                eq("user_123"),
                eq("course_1"),
                eq("lesson_1"),
                anyList()))
                .thenReturn(2L);
        when(lessonProgressRepository.save(any(LessonProgress.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        LessonProgress result = progressService.completeLesson("user_123", "course_1", "lesson_1");

        ArgumentCaptor<LessonProgress> progressCaptor = ArgumentCaptor.forClass(LessonProgress.class);
        verify(lessonProgressRepository).save(progressCaptor.capture());
        LessonProgress saved = progressCaptor.getValue();
        assertNotNull(result.getProgressId());
        assertEquals("user_123", saved.getUserId());
        assertEquals("lesson_1", saved.getLessonId());
        assertEquals("COMPLETED", saved.getStatus());
        assertNotNull(saved.getCompletedAt());
    }

    @Test
    public void completeLesson_WhenLessonHasNoQuestions_Returns409() {
        when(lessonProgressRepository.findByUserIdAndLessonIdAndStatus("user_123", "lesson_empty", "COMPLETED"))
                .thenReturn(Optional.empty());
        when(contentClient.getLessonQuestionIds("course_1", "lesson_empty"))
                .thenReturn(List.of());

        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> progressService.completeLesson("user_123", "course_1", "lesson_empty"));

        assertEquals(HttpStatus.CONFLICT, ex.getStatusCode());
        verify(questionAttemptRepository, never()).countCorrectQuestions(any(), any(), any(), any());
        verify(lessonProgressRepository, never()).save(any());
    }

    @Test
    public void completeLesson_WhenCourseOrLessonNotFound_Returns404() {
        when(lessonProgressRepository.findByUserIdAndLessonIdAndStatus("user_123", "lesson_missing", "COMPLETED"))
                .thenReturn(Optional.empty());
        when(contentClient.getLessonQuestionIds("course_1", "lesson_missing"))
                .thenReturn(null);

        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> progressService.completeLesson("user_123", "course_1", "lesson_missing"));

        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
        verify(questionAttemptRepository, never()).countCorrectQuestions(any(), any(), any(), any());
        verify(lessonProgressRepository, never()).save(any());
    }
}
