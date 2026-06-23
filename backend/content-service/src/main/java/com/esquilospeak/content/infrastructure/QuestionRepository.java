package com.esquilospeak.content.infrastructure;

import com.esquilospeak.content.domain.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuestionRepository extends JpaRepository<Question, String> {
    List<Question> findByLessonId(String lessonId);
}
