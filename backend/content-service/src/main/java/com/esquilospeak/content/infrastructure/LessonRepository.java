package com.esquilospeak.content.infrastructure;

import com.esquilospeak.content.domain.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, String> {
    List<Lesson> findByUnitIdOrderBySequenceOrderAsc(String unitId);
}
