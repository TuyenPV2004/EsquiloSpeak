package com.esquilospeak.learning.service;

import com.esquilospeak.learning.client.ContentClient;
import com.esquilospeak.learning.domain.LessonProgress;
import com.esquilospeak.learning.infrastructure.LessonProgressRepository;
import com.esquilospeak.learning.infrastructure.QuestionAttemptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;

@Service
@Transactional
public class ProgressService {

    @Autowired
    private LessonProgressRepository lessonProgressRepository;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private ContentClient contentClient;

    public LessonProgress completeLesson(String userId, String courseId, String lessonId) {
        // 1. Idempotent check: check if already completed
        Optional<LessonProgress> existing = lessonProgressRepository.findByUserIdAndLessonIdAndStatus(userId, lessonId, "COMPLETED");
        if (existing.isPresent()) {
            return existing.get();
        }

        // 2. Fetch question IDs for this lesson
        List<String> questionIds = contentClient.getLessonQuestionIds(courseId, lessonId);
        if (questionIds == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson or course not found");
        }

        if (questionIds.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Lesson contains no questions");
        }

        // 3. Keep unique question IDs
        Set<String> uniqueQuestionIds = new HashSet<>(questionIds);

        // 4. Count correct attempts for these question IDs
        long correctCount = questionAttemptRepository.countCorrectQuestions(
                userId,
                courseId,
                lessonId,
                new ArrayList<>(uniqueQuestionIds)
        );

        // 5. Verify if learner has completed all questions correctly
        if (correctCount < uniqueQuestionIds.size()) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Not all questions in this lesson have been answered correctly.");
        }

        // 6. Save lesson progress
        String progressId = "prog_" + UUID.randomUUID().toString().replace("-", "");
        LessonProgress progress = new LessonProgress(
                progressId,
                userId,
                lessonId,
                "COMPLETED",
                LocalDateTime.now()
        );

        try {
            return lessonProgressRepository.save(progress);
        } catch (DataIntegrityViolationException ex) {
            // Concurrent request fallback
            return lessonProgressRepository.findByUserIdAndLessonIdAndStatus(userId, lessonId, "COMPLETED")
                    .orElseThrow(() -> ex);
        }
    }
}
