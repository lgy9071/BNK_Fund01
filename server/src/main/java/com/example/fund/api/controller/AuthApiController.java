package com.example.fund.api.controller;

import com.example.fund.api.dto.LoginRequest;
import com.example.fund.api.dto.LoginResponse;
import com.example.fund.api.dto.UserInfo;
import com.example.fund.common.JwtUtil;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Validated
@CrossOrigin(origins = "*") // 개발 중엔 전체 허용, 운영에서는 도메인 제한 권장
public class AuthApiController {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil; // ✅ JwtUtil에 @Component 붙여 빈 등록되어 있어야 함

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        // 1) 사용자 조회
        User user = userRepository.findByUsername(req.getUsername()).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body("invalid credentials");
        }

        // 2) 비밀번호 검증 (BCrypt 또는 평문 - 개발 단계)
        if (!passwordMatches(req.getPassword(), user.getPassword())) {
            return ResponseEntity.status(401).body("invalid credentials");
        }

        // 3) JWT 발급 (보안친화: 최소 정보만)
        String token = jwtUtil.generateToken(
                user.getUsername(),
                user.getUserId(),
                Map.of("roles", "USER"));
        String expiresAt = jwtUtil.getExpiryFromNow().toInstant().toString();

        // 4) 응답 본문에 PII 포함(토큰에는 미포함)
        LoginResponse res = new LoginResponse(
                token,
                expiresAt,
                new UserInfo(
                        user.getUserId(),
                        user.getUsername(),
                        user.getName(),
                        user.getEmail()));

        return ResponseEntity.ok(res);
    }

    private boolean passwordMatches(String raw, String stored) {
        // DB가 BCrypt(권장)일 때
        if (stored != null && stored.startsWith("$2")) {
            return org.mindrot.jbcrypt.BCrypt.checkpw(raw, stored);
        }
        // 개발 단계(평문 저장)일 수 있으니 fallback (운영에서는 금지)
        return raw.equals(stored);
    }
}
