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
public class FundDetailResponse {

    // 기본 정보
    private Long fundId;
    private String fundName;
    private String fundType;
    private String classType;
    private String investmentRegion;
    private LocalDate establishDate;
    private String managementCompany;
    private String baseCurrency;
    private Integer riskLevel;
    private String fundStatus;
    private BigDecimal totalExpenseRatio;
    private String fundTheme;
    private Long termsFileId;
    private Long manualFileId;
    private Long prospectusFileId;
    private String termsFileName;
    private String manualFileName;
    private String prospectusFileName;

    private BigDecimal domesticStock;
    private BigDecimal overseasStock;
    private BigDecimal domesticBond;
    private BigDecimal overseasBond;
    private BigDecimal fundInvestment;
    private BigDecimal liquidity;
}