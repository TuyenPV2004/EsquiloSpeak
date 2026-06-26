package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.QuestionAttempt;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

@Repository
public interface QuestionAttemptRepository extends JpaRepository<QuestionAttempt, String> {
    Optional<QuestionAttempt> findByUserIdAndClientRequestId(String userId, String clientRequestId);
    List<QuestionAttempt> findByUserId(String userId);
    
    long countByUserIdAndCourseId(String userId, String courseId);
    long countByUserIdAndCourseIdAndIsCorrect(String userId, String courseId, boolean isCorrect);

    @Query("SELECT COUNT(a) FROM QuestionAttempt a WHERE a.userId = :userId AND a.courseId = :courseId AND (a.selectedAnswer IS NULL OR a.selectedAnswer <> 'SPOKEN_SELF_REVIEWED')")
    long countNonSpeakingAttempts(@Param("userId") String userId, @Param("courseId") String courseId);

    @Query("SELECT COUNT(a) FROM QuestionAttempt a WHERE a.userId = :userId AND a.courseId = :courseId AND a.isCorrect = :isCorrect AND (a.selectedAnswer IS NULL OR a.selectedAnswer <> 'SPOKEN_SELF_REVIEWED')")
    long countNonSpeakingCorrectAttempts(@Param("userId") String userId, @Param("courseId") String courseId, @Param("isCorrect") boolean isCorrect);

    @Query("SELECT COUNT(DISTINCT a.questionId) FROM QuestionAttempt a " +
           "WHERE a.userId = :userId AND a.courseId = :courseId AND a.lessonId = :lessonId " +
           "AND a.isCorrect = true AND a.questionId IN :questionIds")
    long countCorrectQuestions(
            @Param("userId") String userId,
            @Param("courseId") String courseId,
            @Param("lessonId") String lessonId,
            @Param("questionIds") List<String> questionIds);
}
