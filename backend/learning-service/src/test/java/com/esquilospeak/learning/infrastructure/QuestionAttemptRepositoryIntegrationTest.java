package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.QuestionAttempt;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

import com.esquilospeak.learning.BaseIntegrationTest;
import static org.junit.jupiter.api.Assertions.assertThrows;

@Transactional
public class QuestionAttemptRepositoryIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Test
    public void testUniqueConstraint_DuplicateClientRequestId_ThrowsException() {
        String clientRequestId = "req_" + UUID.randomUUID().toString();
        String userId = "user_test_unique";

        QuestionAttempt attempt1 = new QuestionAttempt(
                "att_" + UUID.randomUUID().toString(),
                clientRequestId,
                userId,
                "course_1",
                "lesson_1",
                "q_1",
                "q_1_v1",
                "Answer 1",
                true,
                1500,
                LocalDateTime.now()
        );

        questionAttemptRepository.saveAndFlush(attempt1);

        QuestionAttempt attempt2 = new QuestionAttempt(
                "att_" + UUID.randomUUID().toString(),
                clientRequestId,
                userId,
                "course_1",
                "lesson_1",
                "q_1",
                "q_1_v1",
                "Answer 2",
                false,
                2000,
                LocalDateTime.now()
        );

        assertThrows(DataIntegrityViolationException.class, () -> {
            questionAttemptRepository.saveAndFlush(attempt2);
        });
    }
}
