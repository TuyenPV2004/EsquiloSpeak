package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.LearningSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LearningSessionRepository extends JpaRepository<LearningSession, String> {
}
