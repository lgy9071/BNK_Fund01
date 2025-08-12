package com.example.common.dto.fund;

import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class JoinRequest {

    @Pattern(regexp = "^[a-z][a-zA-Z0-9]{5,14}$", message = "아이디는 영문 소문자로 시작하고, 영문과 숫자를 포함한 6~15자여야 합니다.")
    private String username;

    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9])\\S{8,15}$",message = "비밀번호는 영문 대소문자, 숫자, 특수문자를 모두 포함한 8~15자여야 합니다.")
    private String password;


    private String confirmPassword;

    @Pattern(regexp = "^[가-힣]{2,4}$",message = "이름은 한글 2~4자로 입력해주세요.")
    private String name;


    @Pattern(
            regexp = "^\\d{2,3}-\\d{3,4}-\\d{4}$",
            message = "전화번호는 010-1234-5678 형식으로 입력해주세요. 숫자와 하이픈(-)을 포함해야 합니다"
    )
    private String phone;

    public boolean samePassword() {
        return password != null && password.equals(confirmPassword);
    }
}
