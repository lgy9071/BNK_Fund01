package com.example.fund.api.dto;

import lombok.Data;

@Data
public class LoginRequest {
    private String username;
    private String password;
    private boolean autoLogin; // ✅ 추가
}