package com.esquilospeak.learning.infrastructure;

import com.esquilospeak.learning.domain.AttemptIdempotencyRecord;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AttemptIdempotencyRecordRepository extends JpaRepository<AttemptIdempotencyRecord, String> {

    Optional<AttemptIdempotencyRecord> findByUserIdAndClientRequestId(String userId, String clientRequestId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM AttemptIdempotencyRecord r WHERE r.userId = :userId AND r.clientRequestId = :clientRequestId")
    Optional<AttemptIdempotencyRecord> findByUserIdAndClientRequestIdForUpdate(
            @Param("userId") String userId,
            @Param("clientRequestId") String clientRequestId);
}
