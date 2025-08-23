package com.example.fund.cdd.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CddRequestDto {
    @NotNull(message = "사용자 ID는 필수입니다")
    private Long userId;

    @NotBlank(message = "주민등록번호는 필수입니다")
    @Pattern(regexp = "\\d{6}-\\d{7}", message = "주민등록번호 형식이 올바르지 않습니다 (예: 901225-1234567)")
    private String residentRegistrationNumber;

    @NotBlank(message = "주소는 필수입니다")
    @Size(max = 255, message = "주소는 255자를 초과할 수 없습니다")
    private String address;

    @NotBlank(message = "국적은 필수입니다")
    @Size(max = 50, message = "국적은 50자를 초과할 수 없습니다")
    private String nationality;

    @NotBlank(message = "직업은 필수입니다")
    @Size(max = 100, message = "직업은 100자를 초과할 수 없습니다")
    private String occupation;

    @NotBlank(message = "소득원은 필수입니다")
    @Pattern(regexp = "급여|사업소득|투자수익|연금|기타", message = "소득원은 '급여', '사업소득', '투자수익', '연금', '기타' 중 하나여야 합니다")
    private String incomeSource;

    @NotBlank(message = "거래목적은 필수입니다")
    @Pattern(regexp = "투자/재테크|생활비 관리|저축/적금|연금 준비|자녀 교육비|기타", message = "거래목적은 지정된 옵션 중 하나여야 합니다")
    private String transactionPurpose;

    @NotBlank(message = "요청시간은 필수입니다")
    private String requestTimestamp;
}
