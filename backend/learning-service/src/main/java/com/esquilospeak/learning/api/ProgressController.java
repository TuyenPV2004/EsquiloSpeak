package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.LessonProgress;
import com.esquilospeak.learning.domain.QuestionAttempt;
import com.esquilospeak.learning.domain.ReviewAttempt;
import com.esquilospeak.learning.infrastructure.LessonProgressRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.esquilospeak.learning.util.HmacUtil;
import com.esquilospeak.learning.client.ContentClient;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/v1")
public class ProgressController {

    private static final Logger log = LoggerFactory.getLogger(ProgressController.class);

    @Value("${analytics.hash-secret}")
    private String hashSecret;

    @Autowired
    private LessonProgressRepository lessonProgressRepository;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private ReviewAttemptRepository reviewAttemptRepository;

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @Autowired
    private ContentClient contentClient;

    @PostMapping("/courses/{courseId}/lessons/{lessonId}/complete")
    public ResponseEntity<?> completeLesson(
            @PathVariable("courseId") String courseId,
            @PathVariable("lessonId") String lessonId,
            @RequestAttribute("userId") String userId) {

        List<LessonProgress> existing = lessonProgressRepository.findByUserId(userId);
        boolean alreadyCompleted = existing.stream().anyMatch(lp -> lp.getLessonId().equalsIgnoreCase(lessonId) && "COMPLETED".equalsIgnoreCase(lp.getStatus()));

        if (!alreadyCompleted) {
            String progressId = "prog_" + UUID.randomUUID().toString().replace("-", "");
            LessonProgress progress = new LessonProgress(
                    progressId,
                    userId,
                    lessonId,
                    "COMPLETED",
                    LocalDateTime.now()
            );
            lessonProgressRepository.save(progress);
        }

        String userHash = HmacUtil.hashUserId(userId, hashSecret);
        log.info("{\"type\":\"analytics\",\"eventName\":\"lesson_completed\",\"userHash\":\"{}\",\"courseId\":\"{}\",\"lessonId\":\"{}\"}",
                userHash, courseId, lessonId);

        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/courses/{courseId}/progress/summary")
    public ResponseEntity<ProgressSummaryResponse> getProgressSummary(
            @PathVariable("courseId") String courseId,
            @RequestAttribute("userId") String userId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        List<String> courseLessonIds = new ArrayList<>();
        try {
            courseLessonIds = contentClient.getCourseLessons(courseId);
        } catch (Exception e) {
            // fallback
        }

        // 2. Count completed lessons
        List<LessonProgress> completedList = lessonProgressRepository.findByUserId(userId);
        Set<String> completedLessonIds = new HashSet<>();
        for (LessonProgress lp : completedList) {
            if ("COMPLETED".equalsIgnoreCase(lp.getStatus())) {
                completedLessonIds.add(lp.getLessonId());
            }
        }

        int completedCount = 0;
        for (String id : courseLessonIds) {
            if (completedLessonIds.contains(id)) {
                completedCount++;
            }
        }

        int totalLessonsCount = courseLessonIds.size();
        double courseCompletionPercent = totalLessonsCount > 0 ? (double) completedCount / totalLessonsCount * 100 : 0.0;

        // 3. Accuracy Calculation
        long totalAttempts = questionAttemptRepository.countNonSpeakingAttempts(userId, courseId);
        long correctAttempts = questionAttemptRepository.countNonSpeakingCorrectAttempts(userId, courseId, true);
        double accuracy = totalAttempts > 0 ? (double) correctAttempts / totalAttempts * 100 : 100.0;

        // 4. Learned Words Count
        long learnedWordsCount = reviewItemRepository.countByUserIdAndCourseId(userId, courseId);

        // 5. Due Review Count
        long dueReviewCount = reviewItemRepository.findByUserIdAndCourseIdAndNextReviewAtBefore(
                userId, courseId, LocalDateTime.now()).size();

        // 6. Streak calculation
        int streak = calculateUserStreak(userId);

        ProgressSummaryResponse response = new ProgressSummaryResponse(
                completedCount,
                totalLessonsCount,
                courseCompletionPercent,
                streak,
                accuracy,
                learnedWordsCount,
                (int) dueReviewCount
        );

        return ResponseEntity.ok(response);
    }

    private int calculateUserStreak(String userId) {
        List<LessonProgress> progressList = lessonProgressRepository.findByUserId(userId);
        List<QuestionAttempt> attemptsList = questionAttemptRepository.findByUserId(userId);
        List<ReviewAttempt> reviewAttemptsList = reviewAttemptRepository.findByUserId(userId);

        Set<LocalDate> activityDates = new HashSet<>();
        for (LessonProgress lp : progressList) {
            if (lp.getCompletedAt() != null) {
                activityDates.add(lp.getCompletedAt().toLocalDate());
            }
        }
        for (QuestionAttempt qa : attemptsList) {
            if (qa.getAnsweredAt() != null) {
                activityDates.add(qa.getAnsweredAt().toLocalDate());
            }
        }
        for (ReviewAttempt ra : reviewAttemptsList) {
            if (ra.getReviewedAt() != null) {
                activityDates.add(ra.getReviewedAt().toLocalDate());
            }
        }

        if (activityDates.isEmpty()) {
            return 0;
        }

        LocalDate today = LocalDate.now();
        LocalDate yesterday = today.minusDays(1);

        if (!activityDates.contains(today) && !activityDates.contains(yesterday)) {
            return 0;
        }

        int streak = 0;
        LocalDate currentDate = activityDates.contains(today) ? today : yesterday;

        while (activityDates.contains(currentDate)) {
            streak++;
            currentDate = currentDate.minusDays(1);
        }

        return streak;
    }

    public static class ProgressSummaryResponse {
        private int completedLessonsCount;
        private int totalLessonsCount;
        private double courseCompletionPercent;
        private int streak;
        private double accuracy;
        private long learnedWordsCount;
        private int dueReviewCount;

        public ProgressSummaryResponse(int completedLessonsCount, int totalLessonsCount, double courseCompletionPercent,
                                       int streak, double accuracy, long learnedWordsCount, int dueReviewCount) {
            this.completedLessonsCount = completedLessonsCount;
            this.totalLessonsCount = totalLessonsCount;
            this.courseCompletionPercent = courseCompletionPercent;
            this.streak = streak;
            this.accuracy = accuracy;
            this.learnedWordsCount = learnedWordsCount;
            this.dueReviewCount = dueReviewCount;
        }

        public int getCompletedLessonsCount() { return completedLessonsCount; }
        public int getTotalLessonsCount() { return totalLessonsCount; }
        public double getCourseCompletionPercent() { return courseCompletionPercent; }
        public int getStreak() { return streak; }
        public double getAccuracy() { return accuracy; }
        public long getLearnedWordsCount() { return learnedWordsCount; }
        public int getDueReviewCount() { return dueReviewCount; }
    }
}
