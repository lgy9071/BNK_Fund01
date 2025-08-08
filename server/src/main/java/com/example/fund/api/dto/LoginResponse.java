package com.example.fund.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class LoginResponse {
    private String accessToken;
    private String expiresAt; // ISO8601 string
    private UserInfo user;
}
