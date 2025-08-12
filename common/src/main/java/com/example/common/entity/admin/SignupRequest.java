package com.example.common.entity.admin;

import lombok.Data;

@Data
public class SignupRequest {
    private String username;
    private String password;
    private String name;
    private String phone;
    private String email;
}
