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
public class FundAssetSummaryDto {
    // private Long fundAssetSummaryId;
    private String fundId;
    private BigDecimal stockRatio;
    private BigDecimal bondRatio;
    private BigDecimal cashRatio;
    private BigDecimal etcRatio;
}