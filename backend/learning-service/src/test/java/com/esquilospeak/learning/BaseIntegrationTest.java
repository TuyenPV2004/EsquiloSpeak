package com.esquilospeak.learning;

import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;

@ExtendWith(DockerAvailableCondition.class)
@SpringBootTest(properties = {
    "spring.security.jwt.secret=ZXNxdWlsb3NwZWFrX3N1cGVyX3NlY3JldF9rZXlfZm9yX212cF90ZXN0aW5nXzEyMzQ1Njc4OTA=",
    "internal.service.token=esquilospeak_internal_s2s_token_for_testing_32_bytes_long"
})
public abstract class BaseIntegrationTest {

    @ServiceConnection
    protected static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("EsquiloSpeak_db")
            .withUsername("esquilospeak")
            .withPassword("123456");
}
