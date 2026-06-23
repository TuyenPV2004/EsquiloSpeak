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
    private RestTemplate restTemplate;

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
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Course course = courseRepository.findById(courseId).orElse(null);
        if (course == null) {
            return ResponseEntity.notFound().build();
        }

        // Find units
        List<Unit> units = unitRepository.findByCourseIdOrderBySequenceOrderAsc(courseId);
        if (units.isEmpty()) {
            return ResponseEntity.ok(new CourseHomeResponse(courseId, null, null, 0, new ArrayList<>(), 0));
        }

        // Pick first unit as active unit for MVP
        Unit activeUnit = units.get(0);

        // Find lessons in active unit
        List<Lesson> lessons = lessonRepository.findByUnitIdOrderBySequenceOrderAsc(activeUnit.getUnitId());
        
        List<LessonInfo> lessonInfos = lessons.stream()
                .map(l -> new LessonInfo(l.getLessonId(), l.getTitle(), "available"))
                .toList();

        // Get due review count from learning-service S2S
        int dueReviewCount = 0;
        try {
            HttpHeaders headers = new HttpHeaders();
            if (authHeader != null) {
                headers.set("Authorization", authHeader);
            }
            HttpEntity<Void> entity = new HttpEntity<>(headers);
            ResponseEntity<Integer> res = restTemplate.exchange(
                "http://learning-service/api/v1/internal/courses/" + courseId + "/reviews/due/count",
                HttpMethod.GET,
                entity,
                Integer.class
            );
            if (res.getBody() != null) {
                dueReviewCount = res.getBody();
            }
        } catch (Exception e) {
            // fallback to 0
        }

        CourseHomeResponse response = new CourseHomeResponse(
                courseId,
                activeUnit.getUnitId(),
                activeUnit.getTitle(),
                0, // 0% progress initially
                lessonInfos,
                dueReviewCount
        );
        return ResponseEntity.ok(response);
    }

    // 6. GET /api/v1/courses/{courseId}/lessons/{lessonId}
    @GetMapping("/courses/{courseId}/lessons/{lessonId}")
    public ResponseEntity<LessonDetailResponse> getLessonDetail(
            @PathVariable("courseId") String courseId,
            @PathVariable("lessonId") String lessonId) {
        
        Lesson lesson = lessonRepository.findById(lessonId).orElse(null);
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
