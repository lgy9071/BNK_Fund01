package com.example.fund.admin.dto;


import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class AdminDTO {

    // 관리자 고유 식별자 (Primary Key 역할)
    private Integer admin_id;

    // 관리자 로그인 아이디
    private String adminname;

    // 관리자 비밀번호
    private String password;

    // 관리자 실제 이름
    private String name;

    // 관리자 권한(Role) 정보 (예: ROLE_ADMIN, ROLE_SUPER 등)
    private String role;
}
