package com.esquilospeak.content.api;

import com.esquilospeak.content.config.InternalServiceAuthInterceptor;
import com.esquilospeak.content.domain.Lesson;
import com.esquilospeak.content.domain.Unit;
import com.esquilospeak.content.domain.Question;
import com.esquilospeak.content.infrastructure.CourseRepository;
import com.esquilospeak.content.infrastructure.UnitRepository;
import com.esquilospeak.content.infrastructure.LessonRepository;
import com.esquilospeak.content.infrastructure.QuestionRepository;
import com.esquilospeak.content.client.LearningServiceClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ContentController.class)
@AutoConfigureMockMvc(addFilters = false)
public class ContentControllerWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CourseRepository courseRepository;

    @MockBean
    private UnitRepository unitRepository;

    @MockBean
    private LessonRepository lessonRepository;

    @MockBean
    private QuestionRepository questionRepository;

    @MockBean
    private LearningServiceClient learningServiceClient;

    @MockBean
    private InternalServiceAuthInterceptor internalServiceAuthInterceptor;

    @BeforeEach
    public void setUp() throws Exception {
        when(internalServiceAuthInterceptor.preHandle(any(), any(), any())).thenReturn(true);
    }

    // --- CLIENT-FACING ENDPOINTS TESTS (/courses/{courseId}/lessons/{lessonId}) ---

    @Test
    public void getLessonDetail_Success_WhenCourseMatches() throws Exception {
        Unit mockUnit = new Unit("unit_1", "course_123", "Unit 1", 1);
        Lesson mockLesson = new Lesson("lesson_1", "unit_1", "Lesson 1", 1, "v1");
        
        when(lessonRepository.findById("lesson_1")).thenReturn(Optional.of(mockLesson));
        when(unitRepository.findById("unit_1")).thenReturn(Optional.of(mockUnit));
        when(questionRepository.findByLessonId("lesson_1")).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/v1/courses/course_123/lessons/lesson_1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lessonId").value("lesson_1"))
                .andExpect(jsonPath("$.title").value("Lesson 1"));

        verify(questionRepository, times(1)).findByLessonId("lesson_1");
    }

    @Test
    public void getLessonDetail_NotFound_WhenCourseMismatched() throws Exception {
        Unit mockUnit = new Unit("unit_1", "course_other", "Unit 1", 1);
        Lesson mockLesson = new Lesson("lesson_1", "unit_1", "Lesson 1", 1, "v1");
        
        when(lessonRepository.findById("lesson_1")).thenReturn(Optional.of(mockLesson));
        when(unitRepository.findById("unit_1")).thenReturn(Optional.of(mockUnit));

        mockMvc.perform(get("/api/v1/courses/course_123/lessons/lesson_1"))
                .andExpect(status().isNotFound());

        verify(questionRepository, never()).findByLessonId(any());
    }

    @Test
    public void getLessonDetail_NotFound_WhenUnitDoesNotExist() throws Exception {
        Lesson mockLesson = new Lesson("lesson_1", "unit_missing", "Lesson 1", 1, "v1");

        when(lessonRepository.findById("lesson_1")).thenReturn(Optional.of(mockLesson));
        when(unitRepository.findById("unit_missing")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/courses/course_123/lessons/lesson_1"))
                .andExpect(status().isNotFound());

        verify(questionRepository, never()).findByLessonId(any());
    }

    @Test
    public void getLessonDetail_NotFound_WhenLessonDoesNotExist() throws Exception {
        when(lessonRepository.findById("lesson_nonexistent")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/courses/course_123/lessons/lesson_nonexistent"))
                .andExpect(status().isNotFound());

        verify(questionRepository, never()).findByLessonId(any());
    }

    // --- INTERNAL ENDPOINTS TESTS (/internal/courses/{courseId}/lessons/{lessonId}/question-ids) ---

    @Test
    public void getLessonQuestionIdsInternal_Success_WhenCourseMatches() throws Exception {
        Unit mockUnit = new Unit("unit_1", "course_123", "Unit 1", 1);
        Lesson mockLesson = new Lesson("lesson_1", "unit_1", "Lesson 1", 1, "v1");
        Question mockQuestion = new Question("q_1", "lesson_1", "Prompt", "multiple_choice", "http://audio.url", "correct_ans", "explanation", "v1", Collections.emptyList());

        when(lessonRepository.findById("lesson_1")).thenReturn(Optional.of(mockLesson));
        when(unitRepository.findById("unit_1")).thenReturn(Optional.of(mockUnit));
        when(questionRepository.findByLessonId("lesson_1")).thenReturn(List.of(mockQuestion));

        mockMvc.perform(get("/api/v1/internal/courses/course_123/lessons/lesson_1/question-ids")
                        .header("X-Internal-Service-Token", "some-token"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").value("q_1"));

        verify(questionRepository, times(1)).findByLessonId("lesson_1");
    }

    @Test
    public void getLessonQuestionIdsInternal_NotFound_WhenCourseMismatched() throws Exception {
        Unit mockUnit = new Unit("unit_1", "course_other", "Unit 1", 1);
        Lesson mockLesson = new Lesson("lesson_1", "unit_1", "Lesson 1", 1, "v1");

        when(lessonRepository.findById("lesson_1")).thenReturn(Optional.of(mockLesson));
        when(unitRepository.findById("unit_1")).thenReturn(Optional.of(mockUnit));

        mockMvc.perform(get("/api/v1/internal/courses/course_123/lessons/lesson_1/question-ids")
                        .header("X-Internal-Service-Token", "some-token"))
                .andExpect(status().isNotFound());

        verify(questionRepository, never()).findByLessonId(any());
    }

    @Test
    public void getLessonQuestionIdsInternal_NotFound_WhenUnitDoesNotExist() throws Exception {
        Lesson mockLesson = new Lesson("lesson_1", "unit_missing", "Lesson 1", 1, "v1");

        when(lessonRepository.findById("lesson_1")).thenReturn(Optional.of(mockLesson));
        when(unitRepository.findById("unit_missing")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/internal/courses/course_123/lessons/lesson_1/question-ids")
                        .header("X-Internal-Service-Token", "some-token"))
                .andExpect(status().isNotFound());

        verify(questionRepository, never()).findByLessonId(any());
    }

    @Test
    public void getLessonQuestionIdsInternal_NotFound_WhenLessonDoesNotExist() throws Exception {
        when(lessonRepository.findById("lesson_nonexistent")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/internal/courses/course_123/lessons/lesson_nonexistent")
                        .header("X-Internal-Service-Token", "some-token"))
                .andExpect(status().isNotFound());

        verify(questionRepository, never()).findByLessonId(any());
    }
}
