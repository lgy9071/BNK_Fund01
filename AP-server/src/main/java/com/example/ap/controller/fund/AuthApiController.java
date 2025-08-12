package com.example.ap.controller.fund;


import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

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

    /** 액세스 연장(항상 사용): 현재 Access 유효해야 함 */
    @PostMapping("/extend")
    public ResponseEntity<TokenResponse> extend(@RequestHeader(HttpHeaders.AUTHORIZATION) String authz) {
        String access = extractBearer(authz);
        var res = userApiService.extendAccess(access);
        return ResponseEntity.ok(res);
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

