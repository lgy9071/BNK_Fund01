package com.example.fund.common;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtUtil {
    private final SecretKey secretKey;
    private final long expirationMillis;

    public JwtUtil(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration-millis}") long expirationMillis) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMillis = expirationMillis;
    }

    public String generateToken(String username, Integer userId, Map<String, Object> claims) {
        long now = System.currentTimeMillis();
        Date issued = new Date(now);
        Date expiry = new Date(now + expirationMillis);

        // secretKey 가 이미 SecretKey 타입이면 그대로 사용
        // (문자열에서 만들려면: SecretKey secretKey =
        // Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));)

        return Jwts.builder()
                .subject(username) // setSubject -> subject
                .claims(claims) // addClaims -> claims
                .claim("uid", userId) // 그대로 사용
                .issuedAt(issued) // setIssuedAt -> issuedAt
                .expiration(expiry) // setExpiration -> expiration
                .signWith(secretKey) // (알고리즘 인자 제거, 키에서 자동 결정)
                .compact();
    }

    public Date getExpiryFromNow() {
        return new Date(System.currentTimeMillis() + expirationMillis);
    }
}
