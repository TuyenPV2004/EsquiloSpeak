package com.esquilospeak.auth.infrastructure;

import com.esquilospeak.auth.domain.GuestAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GuestAccountRepository extends JpaRepository<GuestAccount, String> {
    Optional<GuestAccount> findByDeviceId(String deviceId);
}
