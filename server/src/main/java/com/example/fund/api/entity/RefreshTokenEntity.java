package com.example.fund.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "refresh_tokens")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RefreshTokenEntity {
    @Id
    @Column(name = "token_hash", length = 64)
    private String tokenHash;        // SHA-256 hex

    @Column(name = "user_id", nullable = false)
    private Integer userId;          // ✅ User의 Integer에 맞춤

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;       // now + 30days

    @Column(name = "revoked", nullable = false)
    private boolean revoked;         // 회전/로그아웃 시 true
}