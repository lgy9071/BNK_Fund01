package com.example.common.dto.fund;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class UserInfo {
    private Integer userId;
    private String username;
    private String name;
    private String email;
}
