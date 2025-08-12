package com.example.common.dto.fund;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TokenResponse {
    private String accessToken; // 항상 존재
    private String refreshToken; // 자동로그인 ON이거나 /refresh 호출 시에만 존재(그 외 null)
}
