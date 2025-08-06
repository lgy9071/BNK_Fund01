package com.example.fund.api.common;

import lombok.Data;

@Data
public class SignupRequest {
    private String username;
    private String password;
    private String name;
    private String phone;
    private String email;
}
