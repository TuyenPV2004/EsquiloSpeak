package com.esquilospeak.learning;

import org.junit.jupiter.api.extension.ConditionEvaluationResult;
import org.junit.jupiter.api.extension.ExecutionCondition;
import org.junit.jupiter.api.extension.ExtensionContext;
import org.testcontainers.DockerClientFactory;

public class DockerAvailableCondition implements ExecutionCondition {

    @Override
    public ConditionEvaluationResult evaluateExecutionCondition(ExtensionContext context) {
        boolean dockerAvailable = false;
        try {
            dockerAvailable = DockerClientFactory.instance().isDockerAvailable();
        } catch (Throwable t) {
            dockerAvailable = false;
        }

        boolean isCiMode = isCiRequired();

        if (dockerAvailable) {
            return ConditionEvaluationResult.enabled("Docker environment is available. Integration test will execute.");
        }

        if (isCiMode) {
            throw new IllegalStateException("Docker is required in CI/Release pipeline (CI=true or -Ddocker.tests.required=true) but is unavailable.");
        }

        return ConditionEvaluationResult.disabled("Docker environment is unavailable on local machine. Skipping integration test.");
    }

    private boolean isCiRequired() {
        String sysProp = System.getProperty("docker.tests.required");
        if ("true".equalsIgnoreCase(sysProp)) {
            return true;
        }
        String ciEnv = System.getenv("CI");
        return "true".equalsIgnoreCase(ciEnv);
    }
}
