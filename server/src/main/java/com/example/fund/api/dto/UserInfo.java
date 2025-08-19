package com.example.fund.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class UserInfo {
    private Integer userId;
    private String username;
    private String name;
    private String email;
    private String typename;
}
