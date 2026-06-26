package com.esquilospeak.content.api;

import com.esquilospeak.content.domain.*;
import com.esquilospeak.content.infrastructure.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.HashSet;
import java.util.Base64;
import java.nio.charset.StandardCharsets;
import com.esquilospeak.content.client.LearningServiceClient;
import com.esquilospeak.content.exception.LearningServiceUnavailableException;

@RestController
@RequestMapping("/api/v1")
public class ContentController {

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private UnitRepository unitRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private LearningServiceClient learningServiceClient;

    // 4. GET /api/v1/courses
    @GetMapping("/courses")
    public ResponseEntity<List<Course>> getCourses() {
        List<Course> courses = courseRepository.findAll();
        return ResponseEntity.ok(courses);
    }

    // 5. GET /api/v1/courses/{courseId}/home
    @GetMapping("/courses/{courseId}/home")
    public ResponseEntity<CourseHomeResponse> getCourseHome(
            @PathVariable("courseId") String courseId,
            @RequestAttribute("userId") String userId) {
        Course course = courseRepository.findById(courseId).orElse(null);
        if (course == null) {
            return ResponseEntity.notFound().build();
        }

        // Find units
        List<Unit> units = unitRepository.findByCourseIdOrderBySequenceOrderAsc(courseId);
        if (units.isEmpty()) {
            return ResponseEntity.ok(new CourseHomeResponse(courseId, null, null, 0, new ArrayList<>(), 0));
        }

        // Extract completed lessons from learning-service via S2S
        Set<String> completedLessonIds;
        try {
            completedLessonIds = learningServiceClient.getCompletedLessons(userId);
        } catch (LearningServiceUnavailableException e) {
            return ResponseEntity.status(503).build(); // Service Unavailable
        }

        // Determine active unit dynamically
        Unit activeUnit = null;
        List<Lesson> activeUnitLessons = new ArrayList<>();
        boolean allCourseCompleted = true;

        for (Unit u : units) {
            List<Lesson> lessons = lessonRepository.findByUnitIdOrderBySequenceOrderAsc(u.getUnitId());
            if (lessons.isEmpty()) {
                continue;
            }
            boolean allLessonsInUnitCompleted = true;
            for (Lesson l : lessons) {
                if (!completedLessonIds.contains(l.getLessonId())) {
                    allLessonsInUnitCompleted = false;
                    allCourseCompleted = false;
                    break;
                }
            }
            if (!allLessonsInUnitCompleted && activeUnit == null) {
                activeUnit = u;
                activeUnitLessons = lessons;
            }
        }

        // If all units are completed, or all units are empty, default to the last unit
        if (activeUnit == null) {
            activeUnit = units.get(units.size() - 1);
            activeUnitLessons = lessonRepository.findByUnitIdOrderBySequenceOrderAsc(activeUnit.getUnitId());
        }

        List<LessonInfo> lessonInfos = new ArrayList<>();
        int completedLessonsInActiveUnitCount = 0;
        boolean foundFirstUncompleted = false;

        for (Lesson l : activeUnitLessons) {
            String status;
            if (completedLessonIds.contains(l.getLessonId())) {
                status = "completed";
                completedLessonsInActiveUnitCount++;
            } else {
                if (!foundFirstUncompleted) {
                    status = "available";
                    foundFirstUncompleted = true;
                } else {
                    status = "locked";
                }
            }
            lessonInfos.add(new LessonInfo(l.getLessonId(), l.getTitle(), status));
        }

        // Calculate progress percentage of active unit
        int progressPercent = 0;
        if (allCourseCompleted) {
            progressPercent = 100;
        } else if (!activeUnitLessons.isEmpty()) {
            progressPercent = (int) ((double) completedLessonsInActiveUnitCount / activeUnitLessons.size() * 100);
        }

        // Get due review count from learning-service S2S
        int dueReviewCount = learningServiceClient.getDueReviewCount(courseId, userId);

        CourseHomeResponse response = new CourseHomeResponse(
                courseId,
                activeUnit.getUnitId(),
                activeUnit.getTitle(),
                progressPercent,
                lessonInfos,
                dueReviewCount
        );
        return ResponseEntity.ok(response);
    }

    private java.util.Optional<Lesson> findLessonScopedToCourse(String courseId, String lessonId) {
        return lessonRepository.findById(lessonId)
                .filter(lesson -> lesson.getUnitId() != null)
                .filter(lesson -> unitRepository.findById(lesson.getUnitId())
                        .map(unit -> courseId.equals(unit.getCourseId()))
                        .orElse(false));
    }

    // 6. GET /api/v1/courses/{courseId}/lessons/{lessonId}
    @GetMapping("/courses/{courseId}/lessons/{lessonId}")
    public ResponseEntity<LessonDetailResponse> getLessonDetail(
            @PathVariable("courseId") String courseId,
            @PathVariable("lessonId") String lessonId) {
        
        Lesson lesson = findLessonScopedToCourse(courseId, lessonId).orElse(null);
        if (lesson == null) {
            return ResponseEntity.notFound().build();
        }

        List<Question> questions = questionRepository.findByLessonId(lessonId);
        
        LessonDetailResponse response = new LessonDetailResponse(
                lesson.getLessonId(),
                lesson.getVersionId(),
                lesson.getTitle(),
                questions
        );
        return ResponseEntity.ok(response);
    }

    // Internal endpoint for other microservices
    @GetMapping("/internal/questions/{questionId}")
    public ResponseEntity<Question> getQuestionByIdInternal(@PathVariable("questionId") String questionId) {
        Question question = questionRepository.findById(questionId).orElse(null);
        if (question == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(question);
    }

    // Internal endpoint to retrieve all lesson IDs of a course
    @GetMapping("/internal/courses/{courseId}/lessons")
    public ResponseEntity<List<String>> getCourseLessonIdsInternal(@PathVariable("courseId") String courseId) {
        List<Unit> units = unitRepository.findByCourseIdOrderBySequenceOrderAsc(courseId);
        List<String> lessonIds = new ArrayList<>();
        for (Unit unit : units) {
            List<Lesson> lessons = lessonRepository.findByUnitIdOrderBySequenceOrderAsc(unit.getUnitId());
            for (Lesson lesson : lessons) {
                lessonIds.add(lesson.getLessonId());
            }
        }
        return ResponseEntity.ok(lessonIds);
    }

    // Internal endpoint to retrieve all question IDs of a lesson
    @GetMapping("/internal/courses/{courseId}/lessons/{lessonId}/question-ids")
    public ResponseEntity<List<String>> getLessonQuestionIdsInternal(
            @PathVariable("courseId") String courseId,
            @PathVariable("lessonId") String lessonId) {
        
        Lesson lesson = findLessonScopedToCourse(courseId, lessonId).orElse(null);
        if (lesson == null) {
            return ResponseEntity.notFound().build();
        }

        List<Question> questions = questionRepository.findByLessonId(lessonId);
        List<String> questionIds = questions.stream()
                .map(Question::getQuestionId)
                .toList();
        return ResponseEntity.ok(questionIds);
    }

    // DTO Response Classes
    public static class CourseHomeResponse {
        private String courseId;
        private String activeUnitId;
        private String activeUnitTitle;
        private int progressPercent;
        private List<LessonInfo> lessons;
        private int dueReviewCount;

        public CourseHomeResponse(String courseId, String activeUnitId, String activeUnitTitle, 
                                  int progressPercent, List<LessonInfo> lessons, int dueReviewCount) {
            this.courseId = courseId;
            this.activeUnitId = activeUnitId;
            this.activeUnitTitle = activeUnitTitle;
            this.progressPercent = progressPercent;
            this.lessons = lessons;
            this.dueReviewCount = dueReviewCount;
        }

        public String getCourseId() { return courseId; }
        public String getActiveUnitId() { return activeUnitId; }
        public String getActiveUnitTitle() { return activeUnitTitle; }
        public int getProgressPercent() { return progressPercent; }
        public List<LessonInfo> getLessons() { return lessons; }
        public int getDueReviewCount() { return dueReviewCount; }
    }

    public static class LessonInfo {
        private String lessonId;
        private String title;
        private String status;

        public LessonInfo(String lessonId, String title, String status) {
            this.lessonId = lessonId;
            this.title = title;
            this.status = status;
        }

        public String getLessonId() { return lessonId; }
        public String getTitle() { return title; }
        public String getStatus() { return status; }
    }

    public static class LessonDetailResponse {
        private String lessonId;
        private String lessonVersionId;
        private String title;
        private List<Question> questions;

        public LessonDetailResponse(String lessonId, String lessonVersionId, String title, List<Question> questions) {
            this.lessonId = lessonId;
            this.lessonVersionId = lessonVersionId;
            this.title = title;
            this.questions = questions;
        }

        public String getLessonId() { return lessonId; }
        public String getLessonVersionId() { return lessonVersionId; }
        public String getTitle() { return title; }
        public List<Question> getQuestions() { return questions; }
    }
}
