package com.esquilospeak.content.infrastructure;

import com.esquilospeak.content.domain.Unit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UnitRepository extends JpaRepository<Unit, String> {
    List<Unit> findByCourseIdOrderBySequenceOrderAsc(String courseId);
}
