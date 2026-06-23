package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.LessonProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LessonProgressRepository extends JpaRepository<LessonProgress, String> {
    List<LessonProgress> findByUserId(String userId);
}
