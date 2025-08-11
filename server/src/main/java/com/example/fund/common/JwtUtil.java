package com.example.fund.common;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;
import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtUtil {
    private final SecretKey accessKey;
    private final long accessExpMillis;

    public JwtUtil(
            @Value("${jwt.access-secret}") String accessSecret,
            @Value("${jwt.access-expiration-millis}") long accessExpMillis) {
        this.accessKey = Keys.hmacShaKeyFor(accessSecret.getBytes(StandardCharsets.UTF_8));
        this.accessExpMillis = accessExpMillis; // 10분(=600_000) 권장
    }

    public String generateAccessToken(String username, Integer userId, Map<String, Object> claims) {
        long now = System.currentTimeMillis();
        return Jwts.builder()
                .subject(username)
                .claims(claims) // 추가 클레임 있으면 여기로
                .claim("uid", userId) // ✅ 정수 그대로
                .claim("token_type", "access") // ✅ 구분용
                .issuedAt(new Date(now))
                .expiration(new Date(now + accessExpMillis))
                .signWith(accessKey)
                .compact();
    }

    public Claims parseAccess(String token) {
        return Jwts.parser()
                .verifyWith(accessKey).build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
