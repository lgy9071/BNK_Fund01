package com.example.common.dto.fund;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {

    @NotBlank
    private String username;
    @NotBlank
    private String password;
    private boolean autoLogin; // 추가
}
