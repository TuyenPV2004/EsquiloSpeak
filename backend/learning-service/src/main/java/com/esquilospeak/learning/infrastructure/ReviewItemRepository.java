package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.ReviewItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewItemRepository extends JpaRepository<ReviewItem, String> {
    List<ReviewItem> findByUserIdAndCourseIdAndNextReviewAtBefore(String userId, String courseId, LocalDateTime now);
    Optional<ReviewItem> findByUserIdAndCourseIdAndConcept(String userId, String courseId, String concept);
    long countByUserIdAndCourseId(String userId, String courseId);
}
