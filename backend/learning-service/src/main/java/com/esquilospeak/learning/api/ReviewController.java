package com.esquilospeak.learning.api;

import com.esquilospeak.learning.config.JwtTokenUtil;
import com.esquilospeak.learning.domain.ReviewItem;
import com.esquilospeak.learning.domain.ReviewAttempt;
import com.esquilospeak.learning.infrastructure.ReviewItemRepository;
import com.esquilospeak.learning.infrastructure.ReviewAttemptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.Clock;
import com.esquilospeak.learning.service.Sm2Scheduler;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class ReviewController {

    @Autowired
    private ReviewItemRepository reviewItemRepository;

    @Autowired
    private ReviewAttemptRepository reviewAttemptRepository;

    @Autowired
    private Clock clock;

    @GetMapping("/courses/{courseId}/reviews/due")
    public ResponseEntity<?> getDueReviews(
            @PathVariable("courseId") String courseId,
            @RequestAttribute(value = "userId", required = false) String userId) {

        if (userId == null || userId.trim().isEmpty()) {
            return ResponseEntity.status(401).body("Unauthorized: Missing user authentication context");
        }

        List<ReviewItem> dueReviews = reviewItemRepository.findByUserIdAndCourseIdAndNextReviewAtBefore(
                userId, courseId, LocalDateTime.now(clock));
        return ResponseEntity.ok(dueReviews);
    }

    @PostMapping("/courses/{courseId}/review-attempts")
    public ResponseEntity<?> submitReviewAttempt(
            @PathVariable("courseId") String courseId,
            @RequestAttribute(value = "userId", required = false) String userId,
            @RequestBody ReviewAttemptRequest request) {

        if (userId == null || userId.trim().isEmpty()) {
            return ResponseEntity.status(401).body("Unauthorized: Missing user authentication context");
        }

        Optional<ReviewItem> reviewItemOpt = reviewItemRepository.findById(request.getReviewItemId());
        if (reviewItemOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        ReviewItem reviewItem = reviewItemOpt.get();
        if (!reviewItem.getUserId().equalsIgnoreCase(userId)) {
            return ResponseEntity.status(403).body("Unauthorized to review this item");
        }

        // Map rating to SM-2 quality q (0-5)
        String rating = request.getRating() != null ? request.getRating().trim().toLowerCase() : "good";
        int q;
        switch (rating) {
            case "again":
                q = 1;
                break;
            case "hard":
                q = 3;
                break;
            case "easy":
                q = 5;
                break;
            case "good":
            default:
                q = 4;
                break;
        }

        Sm2Scheduler.calculateNextReview(reviewItem, q, clock);

        reviewItemRepository.save(reviewItem);

        // Save ReviewAttempt
        String attemptId = "rat_" + UUID.randomUUID().toString().replace("-", "");
        ReviewAttempt reviewAttempt = new ReviewAttempt(
                attemptId,
                userId,
                reviewItem.getReviewItemId(),
                rating,
                request.getResponseTimeMs(),
                LocalDateTime.now(clock)
        );
        reviewAttemptRepository.save(reviewAttempt);

        return ResponseEntity.ok(new ReviewAttemptResponse(true, reviewItem.getNextReviewAt().toString()));
    }

    // Internal S2S endpoint
    @GetMapping("/internal/courses/{courseId}/reviews/due/count")
    public ResponseEntity<Integer> getDueReviewsCount(
            @PathVariable("courseId") String courseId,
            @RequestParam("userId") String userId) {

        if (userId == null || userId.trim().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        List<ReviewItem> dueReviews = reviewItemRepository.findByUserIdAndCourseIdAndNextReviewAtBefore(
                userId, courseId, LocalDateTime.now(clock));
        return ResponseEntity.ok(dueReviews.size());
    }

    // DTOs
    public static class ReviewAttemptRequest {
        private String reviewItemId;
        private String rating;
        private int responseTimeMs;

        public String getReviewItemId() { return reviewItemId; }
        public void setReviewItemId(String reviewItemId) { this.reviewItemId = reviewItemId; }

        public String getRating() { return rating; }
        public void setRating(String rating) { this.rating = rating; }

        public int getResponseTimeMs() { return responseTimeMs; }
        public void setResponseTimeMs(int responseTimeMs) { this.responseTimeMs = responseTimeMs; }
    }

    public static class ReviewAttemptResponse {
        private boolean success;
        private String nextReviewAt;

        public ReviewAttemptResponse(boolean success, String nextReviewAt) {
            this.success = success;
            this.nextReviewAt = nextReviewAt;
        }

        public boolean isSuccess() { return success; }
        public String getNextReviewAt() { return nextReviewAt; }
    }
}
