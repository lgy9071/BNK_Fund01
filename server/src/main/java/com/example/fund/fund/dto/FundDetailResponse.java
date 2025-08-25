package com.example.fund.fund.dto;

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
    private String fundId;
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

    private FundProductView product; // 목록에 Product 데이터 보이기
    private Long productId;
}