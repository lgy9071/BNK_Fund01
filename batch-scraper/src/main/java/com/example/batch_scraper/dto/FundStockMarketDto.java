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
public class FundStockMarketDto {
    // private Long fundStockMarketId;
    private String fundId;
    private BigDecimal kseRatio;
    private BigDecimal kosdaqRatio;
    private BigDecimal otherRatio;
}