package com.esquilospeak.auth.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "guest_accounts", schema = "auth_schema")
public class GuestAccount {

    @Id
    @Column(name = "user_id", length = 36)
    private String userId;

    @Column(name = "device_id", unique = true, nullable = false)
    private String deviceId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public GuestAccount() {
    }

    public GuestAccount(String userId, String deviceId, LocalDateTime createdAt) {
        this.userId = userId;
        this.deviceId = deviceId;
        this.createdAt = createdAt;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
