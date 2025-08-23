package com.example.fund.account.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

// 계좌 생성 요청 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateDepositAccountRequestDto {

    @NotNull(message = "사용자 ID는 필수입니다.")
    private Integer userId;

    @Size(max = 50, message = "계좌 별칭은 50자를 초과할 수 없습니다.")
    private String accountName; // nullable, 기본값은 서비스에서 처리

    @NotBlank(message = "계좌 비밀번호는 필수입니다.")
    @Size(min = 4, max = 6, message = "계좌 비밀번호는 4~6자리여야 합니다.")
    @Pattern(regexp = "^[0-9]+$", message = "계좌 비밀번호는 숫자만 입력 가능합니다.")
    private String pin; // 평문 PIN (해시 전)
}