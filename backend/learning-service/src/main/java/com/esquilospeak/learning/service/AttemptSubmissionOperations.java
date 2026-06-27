package com.esquilospeak.learning.service;

import com.esquilospeak.learning.api.AttemptController.AttemptRequest;
import com.esquilospeak.learning.api.SyncController.SyncResult;
import com.esquilospeak.learning.service.AttemptSubmissionService.AttemptSubmissionResult;

public interface AttemptSubmissionOperations {
    AttemptSubmissionResult submitOnlineAttempt(String userId, String pathCourseId, AttemptRequest request);
    SyncResult syncAttempt(String userId, AttemptRequest request);
}
