package com.example.common.dto.fund;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 펀드 상세 정보 응답 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FundDetailResponseDTO {
    // 펀드 기본 정보
    private Long fundId;
    private String fundName;
    private String fundType;
    private String investmentRegion;
    private LocalDate establishDate;
    private LocalDate launchDate;
    private BigDecimal nav;
    private Integer aum;
    private BigDecimal totalExpenseRatio;
    private Integer riskLevel;
    private String managementCompany;

    // 펀드 수익률 정보
    private BigDecimal return1m;
    private BigDecimal return3m;
    private BigDecimal return6m;
    private BigDecimal return12m;
    private BigDecimal returnSince;

    // 펀드 포트폴리오 정보
    private BigDecimal domesticStock;
    private BigDecimal overseasStock;
    private BigDecimal domesticBond;
    private BigDecimal overseasBond;
    private BigDecimal fundInvestment;
    private BigDecimal liquidity;

    // 접근 권한 정보
    private boolean accessAllowed;
    private String accessMessage;
    private Integer userInvestType;
    private Integer requiredMinRiskLevel;
}
