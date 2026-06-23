package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.ReviewAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewAttemptRepository extends JpaRepository<ReviewAttempt, String> {
    List<ReviewAttempt> findByUserIdAndReviewItemId(String userId, String reviewItemId);
    List<ReviewAttempt> findByUserId(String userId);
}
