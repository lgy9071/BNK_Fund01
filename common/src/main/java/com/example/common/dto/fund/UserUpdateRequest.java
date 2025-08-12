package com.example.common.dto.fund;

import jakarta.validation.constraints.Pattern;
import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class UserUpdateRequest {

    // ✅ 아이디 (readonly 출력용)
    private String username;

    // 현재 비밀번호
    private String currentPassword;

    // 새 비밀번호
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9])\\S{8,15}$",
            message = "새 비밀번호는 영문 대소문자·숫자·특수문자 포함 8~15자"
    )
    private String newPassword;

    // 새 비밀번호 확인
    private String confirmNewPassword;

    // 이름
    @Pattern(regexp="^[가-힣]{2,4}$", message="이름은 한글 2~4자")
    private String name;

    // 전화번호
    @Pattern(
            regexp="^\\d{2,3}-\\d{3,4}-\\d{4}$",
            message="전화번호는 010-1234-5678 형식"
    )
    private String phone;

    // 비밀번호 변경 여부 체크
    public boolean isChangingPassword() {
        return newPassword != null && !newPassword.isBlank();
    }

    // 새 비밀번호 일치 여부
    public boolean newPwMatches() {
        return newPassword != null && newPassword.equals(confirmNewPassword);
    }
}

