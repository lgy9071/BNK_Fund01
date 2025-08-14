package com.example.fund.api.controller;

import com.example.fund.api.dto.LoginRequest;
import com.example.fund.api.dto.TokenResponse;
import com.example.fund.api.service.UserApiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Validated
@CrossOrigin(origins = "*")
public class AuthApiController {

    private final UserApiService userApiService;

    /** 로그인: Access(10분) + (autoLogin=true면) Refresh(30일) */
    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody LoginRequest req) {
        var res = userApiService.loginIssueTokens(req.getUsername(), req.getPassword(), req.isAutoLogin());
        return ResponseEntity.ok(res);
    }

    @PostMapping("/extend")
    public ResponseEntity<TokenResponse> extend(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authz) {

        String access = extractBearerRelaxed(authz); // 헤더 없는 경우/형식 이상 처리 포함
        TokenResponse res = userApiService.extendAccessAllowExpired(access);
        return ResponseEntity.ok(res);
    }

    /** "Bearer <token>" 에서 token만 안전하게 추출 (제로폭/nbsp/공백 제거) */
    private String extractBearerRelaxed(String authz) {
        if (authz == null || authz.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.UNAUTHORIZED, "Missing token");
        }
        String v = authz.replaceAll("[\\u200B-\\u200D\\uFEFF\\u00A0]", "").trim();
        if (v.regionMatches(true, 0, "Bearer ", 0, 7)) {
            v = v.substring(7);
        }
        v = v.replaceAll("\\s+", "").trim();
        if (v.isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.UNAUTHORIZED, "Invalid token");
        }
        return v;
    }

    /** 리프레시(자동로그인 ON일 때만): 회전 + 새 Access/Refresh */
    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@RequestBody RefreshReq req) {
        var res = userApiService.refreshRotate(req.refreshToken());
        return ResponseEntity.ok(res);
    }

    /** 로그아웃: 전달된 refresh revoke */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody RefreshReq req) {
        userApiService.logoutByRefresh(req.refreshToken());
        return ResponseEntity.noContent().build();
    }

    // ----------------- helpers & DTOs -----------------
    // 헤더에서 "Bearer " 잘라내기 전용
    private String extractBearer(String authz) {
        if (authz == null || !authz.startsWith("Bearer ")) {
            throw new RuntimeException("no bearer token");
        }
        return authz.substring(7);
    }

    // refresh 토큰 JSON 바디 매핑용 DTO
    public record RefreshReq(String refreshToken) {
    }
}
