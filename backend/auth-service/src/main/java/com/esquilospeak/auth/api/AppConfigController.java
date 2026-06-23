package com.esquilospeak.auth.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class AppConfigController {

    @GetMapping("/app-config")
    public ResponseEntity<AppConfigResponse> getAppConfig() {
        LanguageInfo en = new LanguageInfo("en", "English");
        AppConfigResponse response = new AppConfigResponse("1.0.0", false, List.of(en));
        return ResponseEntity.ok(response);
    }

    public static class AppConfigResponse {
        private String latestAppVersion;
        private boolean forceUpdate;
        private List<LanguageInfo> supportedLanguages;

        public AppConfigResponse(String latestAppVersion, boolean forceUpdate, List<LanguageInfo> supportedLanguages) {
            this.latestAppVersion = latestAppVersion;
            this.forceUpdate = forceUpdate;
            this.supportedLanguages = supportedLanguages;
        }

        public String getLatestAppVersion() { return latestAppVersion; }
        public boolean isForceUpdate() { return forceUpdate; }
        public List<LanguageInfo> getSupportedLanguages() { return supportedLanguages; }
    }

    public static class LanguageInfo {
        private String code;
        private String name;

        public LanguageInfo(String code, String name) {
            this.code = code;
            this.name = name;
        }

        public String getCode() { return code; }
        public String getName() { return name; }
    }
}
