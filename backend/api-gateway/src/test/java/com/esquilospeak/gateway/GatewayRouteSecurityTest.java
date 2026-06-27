package com.esquilospeak.gateway;

import org.junit.jupiter.api.Test;
import org.springframework.util.AntPathMatcher;
import org.yaml.snakeyaml.Yaml;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class GatewayRouteSecurityTest {

    private final AntPathMatcher pathMatcher = new AntPathMatcher();

    @Test
    public void gatewayRoutes_DoNotExposeInternalApiPaths() throws IOException {
        List<String> routePatterns = loadGatewayPathPredicates();

        assertFalse(matchesAny(routePatterns, "/api/v1/internal/courses/en_for_vi/reviews/due/count"));
        assertFalse(matchesAny(routePatterns, "/api/v1/internal/questions/q_1"));
    }

    @Test
    public void gatewayRoutes_StillExposeExpectedPublicLearningEndpoints() throws IOException {
        List<String> routePatterns = loadGatewayPathPredicates();

        assertTrue(matchesAny(routePatterns, "/api/v1/sync/attempts"));
        assertTrue(matchesAny(routePatterns, "/api/v1/courses/en_for_vi/attempts"));
        assertTrue(matchesAny(routePatterns, "/api/v1/courses/en_for_vi/lessons/lesson_1/complete"));
    }

    private boolean matchesAny(List<String> routePatterns, String path) {
        return routePatterns.stream().anyMatch(pattern -> pathMatcher.match(pattern, path));
    }

    @SuppressWarnings("unchecked")
    private List<String> loadGatewayPathPredicates() throws IOException {
        Path applicationYaml = Path.of("src/main/resources/application.yml");
        try (InputStream input = Files.newInputStream(applicationYaml)) {
            Map<String, Object> root = new Yaml().load(input);
            Map<String, Object> spring = (Map<String, Object>) root.get("spring");
            Map<String, Object> cloud = (Map<String, Object>) spring.get("cloud");
            Map<String, Object> gateway = (Map<String, Object>) cloud.get("gateway");
            List<Map<String, Object>> routes = (List<Map<String, Object>>) gateway.get("routes");

            List<String> pathPredicates = new ArrayList<>();
            for (Map<String, Object> route : routes) {
                List<String> predicates = (List<String>) route.get("predicates");
                for (String predicate : predicates) {
                    if (predicate.startsWith("Path=")) {
                        String[] patterns = predicate.substring("Path=".length()).split(",");
                        for (String pattern : patterns) {
                            pathPredicates.add(pattern.trim());
                        }
                    }
                }
            }
            return pathPredicates;
        }
    }
}
