package com.esquilospeak.auth.api;

import com.esquilospeak.auth.config.JwtTokenUtil;
import com.esquilospeak.auth.domain.GuestAccount;
import com.esquilospeak.auth.domain.UserProfile;
import com.esquilospeak.auth.infrastructure.GuestAccountRepository;
import com.esquilospeak.auth.infrastructure.UserProfileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    @Autowired
    private GuestAccountRepository guestAccountRepository;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @PostMapping("/guest")
    public ResponseEntity<GuestAuthResponse> authenticateGuest(@RequestBody GuestAuthRequest request) {
        String deviceId = request.getDeviceId();
        if (deviceId == null || deviceId.trim().isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        GuestAccount guest = guestAccountRepository.findByDeviceId(deviceId)
                .orElseGet(() -> {
                    String userId = "usr_" + UUID.randomUUID().toString().replace("-", "");
                    
                    // Create guest account in auth schema
                    GuestAccount newGuest = new GuestAccount(userId, deviceId, LocalDateTime.now());
                    GuestAccount savedGuest = guestAccountRepository.save(newGuest);

                    // Initialize empty user profile in user schema
                    UserProfile profile = new UserProfile(userId, LocalDateTime.now());
                    userProfileRepository.save(profile);

                    return savedGuest;
                });

        String token = JwtTokenUtil.generateToken(guest.getUserId(), guest.getDeviceId());
        GuestAuthResponse response = new GuestAuthResponse(token, guest.getUserId(), guest.getDeviceId());
        return ResponseEntity.ok(response);
    }

    public static class GuestAuthRequest {
        private String deviceId;

        public String getDeviceId() { return deviceId; }
        public void setDeviceId(String deviceId) { this.deviceId = deviceId; }
    }

    public static class GuestAuthResponse {
        private String accessToken;
        private String userId;
        private String deviceId;

        public GuestAuthResponse(String accessToken, String userId, String deviceId) {
            this.accessToken = accessToken;
            this.userId = userId;
            this.deviceId = deviceId;
        }

        public String getAccessToken() { return accessToken; }
        public String getUserId() { return userId; }
        public String getDeviceId() { return deviceId; }
    }
}
