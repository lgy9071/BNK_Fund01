package com.example.fund.api.controller;

import com.example.fund.api.dto.UserInfo;
import com.example.fund.api.service.UserApiService;
import com.example.fund.common.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserApiController {

    private final UserApiService userApiService;
    private final JwtUtil jwtUtil;

    /** 로그인한 “나” 정보 */
    @GetMapping("/me")
    public UserInfo me(@RequestHeader(HttpHeaders.AUTHORIZATION) String authz) {
        String access = extractBearerRelaxed(authz);       // 아래 helper 그대로 사용
        var claims = jwtUtil.parseAccess(access);          // 유효한 access여야 함
        Integer uid = claims.get("uid", Integer.class);
        return userApiService.getUserInfo(uid);
    }

    /** (선택) 특정 ID로 사용자 조회 - 관리/디버그 용 */
    @GetMapping("/{id}")
    public UserInfo getById(@PathVariable Integer id) {
        return userApiService.getUserInfo(id);
    }

    // --- helper: AuthApiController에 있던 relaxed 추출기 재사용/복붙 ---
    private String extractBearerRelaxed(String authz) {
        if (authz == null || authz.isBlank())
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.UNAUTHORIZED, "Missing token");
        String v = authz.replaceAll("[\\u200B-\\u200D\\uFEFF\\u00A0]", "").trim();
        if (v.regionMatches(true, 0, "Bearer ", 0, 7)) v = v.substring(7);
        v = v.replaceAll("\\s+", "").trim();
        if (v.isEmpty())
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.UNAUTHORIZED, "Invalid token");
        return v;
    }
}