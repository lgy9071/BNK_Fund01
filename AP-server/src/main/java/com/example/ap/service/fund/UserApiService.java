package com.example.ap.service.fund;

    import java.time.Instant;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.ap.repository.fund.RefreshTokenRepository;
import com.example.ap.repository.fund.UserRepository;
import com.example.ap.util.jwt.JwtUtil;
import com.example.common.dto.fund.TokenResponse;
import com.example.common.entity.admin.SignupRequest;
import com.example.common.entity.fund.RefreshTokenEntity;
import com.example.common.entity.fund.User;
import com.example.common.util.jwt.OpaqueTokenUtil;

import lombok.RequiredArgsConstructor;

    @Service
    @RequiredArgsConstructor
    public class UserApiService {

        private final UserRepository userRepository;
        private final BCryptPasswordEncoder passwordEncoder;

        // ✅ 토큰 관련 의존성 추가
        private final JwtUtil jwtUtil; // Access JWT
        private final RefreshTokenRepository refreshRepo; // Refresh 저장

        @Value("${refresh.ttl-seconds:2592000}") // 기본 30일
        private long refreshTtlSeconds;

        /* -------------------- 회원가입/중복체크(기존 유지) -------------------- */

        public boolean existsByUsername(String username) {
            return userRepository.existsByUsername(username);
        }

        @Transactional
        public User save(SignupRequest req) {
            if (userRepository.existsByUsername(req.getUsername())) {
                throw new IllegalArgumentException("이미 사용 중인 아이디입니다.");
            }

            User user = User.builder()
                    .username(req.getUsername().trim())
                    .password(passwordEncoder.encode(req.getPassword()))
                    .name(req.getName())
                    .phone(req.getPhone())
                    .email(req.getEmail())
                    .build();
            return userRepository.save(user);
        }

        /* -------------------- 여기부터 토큰 관련 메서드 -------------------- */

        /**
         * 로그인: 항상 Access(10분) 발급, autoLogin=true면 Refresh(30일, 회전 대상)도 발급
         */
        @Transactional
        public TokenResponse loginIssueTokens(String username, String rawPassword, boolean autoLogin) {
            User user = userRepository.findByUsername(username).orElse(null);
            if (user == null || !matches(rawPassword, user.getPassword())) {
                throw new UnauthorizedException("invalid credentials");
            }

            String access = jwtUtil.generateAccessToken(user.getUsername(), user.getUserId(), Map.of());
            String refresh = null;
            if (autoLogin) {
                refresh = issueRefresh(user.getUserId());
            }
            return new TokenResponse(access, refresh);
        }

        /**
         * 액세스 연장(항상 사용): 현재 Access가 아직 유효해야 함. 새 Access(10분) 재발급
         */
        public TokenResponse extendAccess(String currentAccess) {
            var claims = jwtUtil.parseAccess(currentAccess); // 만료 후면 예외
            Integer uid = claims.get("uid", Integer.class);
            String username = claims.getSubject();

            String newAccess = jwtUtil.generateAccessToken(username, uid, Map.of());
            return new TokenResponse(newAccess, null);
        }

        /**
         * 리프레시(자동로그인 ON일 때): 검증 → 회전 → 새 Access + 새 Refresh 발급
         */
        @Transactional
        public TokenResponse refreshRotate(String refreshRaw) {
            String hash = OpaqueTokenUtil.sha256Hex(refreshRaw);
            RefreshTokenEntity cur = refreshRepo.findById(hash)
                    .orElseThrow(() -> new UnauthorizedException("invalid refresh"));

            if (cur.isRevoked() || cur.getExpiresAt().isBefore(Instant.now())) {
                throw new UnauthorizedException("expired/revoked refresh");
            }

            // 회전: 현재 것 revoke
            cur.setRevoked(true);
            refreshRepo.save(cur);

            // 새 refresh 발급/저장
            String newRefreshRaw = issueRefresh(cur.getUserId());

            // 새 access 발급(username은 필요 시 조회)
            User u = userRepository.findById(cur.getUserId())
                    .orElseThrow(() -> new UnauthorizedException("user not found"));
            String newAccess = jwtUtil.generateAccessToken(u.getUsername(), u.getUserId(), Map.of());

            return new TokenResponse(newAccess, newRefreshRaw);
        }

        /**
         * 로그아웃: 전달된 refresh를 revoke
         */
        @Transactional
        public void logoutByRefresh(String refreshRaw) {
            String hash = OpaqueTokenUtil.sha256Hex(refreshRaw);
            refreshRepo.findById(hash).ifPresent(rt -> {
                rt.setRevoked(true);
                refreshRepo.save(rt);
            });
        }

        /* -------------------- 내부 유틸 -------------------- */

        private boolean matches(String raw, String stored) {
            if (stored == null)
                return false;
            // BCrypt 저장이면 BCrypt 매칭
            if (stored.startsWith("$2a$") || stored.startsWith("$2b$") || stored.startsWith("$2y$")) {
                return passwordEncoder.matches(raw, stored);
            }
            // 개발 단계 평문 대비(운영 금지)
            return raw.equals(stored);
        }

        private String issueRefresh(Integer userId) {
            String raw = OpaqueTokenUtil.generate();
            String hash = OpaqueTokenUtil.sha256Hex(raw);

            RefreshTokenEntity e = RefreshTokenEntity.builder()
                    .tokenHash(hash)
                    .userId(userId) // Integer로 저장
                    .expiresAt(Instant.now().plusSeconds(refreshTtlSeconds))
                    .revoked(false)
                    .build();
            refreshRepo.save(e);
            return raw; // 클라이언트엔 원본 전달, 서버엔 해시만 저장
        }

        /* -------------------- 에러 타입 -------------------- */
        public static class UnauthorizedException extends RuntimeException {
            public UnauthorizedException(String msg) {
                super(msg);
            }
        }
    }

