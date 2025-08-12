package com.example.common.dto.fund;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 펀드 목록 정보 응답 DTO
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundPolicyResponseDTO {
    private Long fundId;    // 펀드 ID
    private String fundName;    // 펀드명
    private String fundType;    // 펀드 유형
    private String investmentRegion;    // 투자 지역
    private LocalDate establishDate;    // 설정일
    private LocalDate fundRelease;           // 개시일 - fund_Release 변경
    private LocalDate launchDate;           // 출범일 - deprecated
    private BigDecimal nav;                 // 기준금
    private Integer aum;                    // 순자산
    private BigDecimal totalExpenseRatio;   // 총 보수율
    private Integer riskLevel;          // 위험 등급
    private String managementCompany;   // 운용사

    // Fund_Policy 관련
    private String fundTheme;               // 펀드 테마

    // Fund_Return 관련
    private BigDecimal return1m;    // 1개월
    private BigDecimal return3m;    // 3개월
    private BigDecimal return6m;    // 6개월
    private BigDecimal return12m;   // 12개월
    private BigDecimal returnSince; // 누적
}