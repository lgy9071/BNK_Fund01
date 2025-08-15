package com.example.batch_scraper.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundLiquidityAssetsDto {
    // private Long fundLiquidityAssetsId;
    private String fundId;
    private BigDecimal cdRatio;
    private BigDecimal cpRatio;
    private BigDecimal callLoanRatio;
    private BigDecimal depositRatio;
    private BigDecimal otherRatio;
}