package com.example.fund.api.service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.api.common.SignupRequest;
import com.example.fund.api.dto.TokenResponse;
import com.example.fund.api.entity.RefreshTokenEntity;
import com.example.fund.api.repository.RefreshTokenRepository;
import com.example.fund.common.JwtUtil;
import com.example.fund.common.OpaqueTokenUtil;
import com.example.fund.fund.entity.InvestProfileResult;
import com.example.fund.fund.service.InvestProfileService;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;

import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserApiService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final InvestProfileService investProfileService;

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

    @Transactional(readOnly = true)
    public User getById(Integer userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found: " + userId));
    }

    public String getByTypeName(User user) {
        Optional<InvestProfileResult> resultOpt = investProfileService.getLatestResult(user);
        InvestProfileResult r = resultOpt.get();

        String typename = r.getType().getTypeName();

        return typename;
    }
    /* -------------------- 여기부터 토큰 관련 메서드 -------------------- */

    /**
     * 로그인: access는 항상 발급, autoLogin=true면 refresh 신규 발급/저장
     */
    @Transactional
    public TokenResponse loginIssueTokens(String username, String rawPassword, boolean autoLogin) {
        // 1) 사용자 조회 + 비번 검증
        User u = userRepository.findByUsername(username)
                .orElseThrow(() -> new UnauthorizedException("user not found"));
        if (!passwordEncoder.matches(rawPassword, u.getPassword())) {
            throw new UnauthorizedException("bad credentials");
        }

        // 2) access 토큰 발급
        String access = jwtUtil.generateAccessToken(u.getUsername(), u.getUserId(), Map.of());

        // 3) autoLogin 체크 시 refresh 신규 발급/저장
        String refreshRaw = null;
        if (autoLogin) {
            refreshRaw = issueRefresh(u.getUserId());
        }

        // 4) 응답: access 항상, refresh는 autoLogin일 때만
        return new TokenResponse(access, refreshRaw);
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
     * 액세스 연장(항상 사용): 만료 상태일때도 Refresh토큰을 검사해서 새 Access(10분) 재발급
     */

    @Transactional
    public TokenResponse extendAccessAllowExpired(String accessToken) {
        Claims c = jwtUtil.parseAccessAllowExpired(accessToken); // ✅ 만료 허용 파싱
        if (!"access".equals(c.get("token_type"))) {
            throw new UnauthorizedException("invalid token_type");
        }

        Integer uid = c.get("uid", Integer.class);
        if (uid == null)
            throw new UnauthorizedException("missing uid");

        var user = userRepository.findById(uid).orElseThrow();
        String newAccess = jwtUtil.generateAccessToken(user.getUsername(), uid, Map.of());
        return new TokenResponse(newAccess, null);
    }

    // 바깥 메서드엔 @Transactional 걸지 말 것! (안에서 트랜잭션을 2번 나눠서 쓸 거라)
    public TokenResponse refreshRotate(String refreshRaw) {
        log.info("refreshRotate called id={}", java.util.UUID.randomUUID());

        // 1) revoke를 독립 트랜잭션으로 처리하고 userId 반환
        Integer userId = revokeRefreshInNewTx(refreshRaw);

        // 2) 새 refresh 발급/저장도 독립 트랜잭션으로
        String newRefreshRaw = issueRefreshInNewTx(userId);

        // 3) access 토큰은 DB에 안 쓰니 그냥 여기서 생성
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new UnauthorizedException("user not found"));
        String newAccess = jwtUtil.generateAccessToken(u.getUsername(), u.getUserId(), java.util.Map.of());

        return new TokenResponse(newAccess, newRefreshRaw);
    }

    /** 현재 refresh를 revoke만 하고 commit (독립 트랜잭션) */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Integer revokeRefreshInNewTx(String refreshRaw) {
        String hash = OpaqueTokenUtil.sha256Hex(refreshRaw);
        RefreshTokenEntity cur = refreshRepo.findById(hash)
                .orElseThrow(() -> new UnauthorizedException("invalid refresh"));

        if (cur.isRevoked() || cur.getExpiresAt().isBefore(java.time.Instant.now())) {
            throw new UnauthorizedException("expired/revoked refresh");
        }

        cur.setRevoked(true);
        // 벌크/네이티브가 아니면 save로 충분. 확실히 하고 싶으면 saveAndFlush
        refreshRepo.save(cur);
        return cur.getUserId();
    }

    /** 새 refresh를 발급/저장하고 바로 commit (독립 트랜잭션) */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String issueRefreshInNewTx(Integer userId) {
        String raw = OpaqueTokenUtil.generate(); // 이미 있으니 그대로 사용
        String hash = OpaqueTokenUtil.sha256Hex(raw);

        RefreshTokenEntity e = new RefreshTokenEntity();
        e.setTokenHash(hash);
        e.setUserId(userId);
        e.setRevoked(false);
        e.setExpiresAt(java.time.Instant.now().plus(java.time.Duration.ofDays(30)));

        refreshRepo.save(e);
        return raw; // 해시가 아닌 RAW를 클라이언트에 내려줌
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
