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
public class FundFeeInfoDto {
    // private Long fundFeeInfoId;
    private String fundId;
    private BigDecimal managementFee;
    private BigDecimal salesFee;
    private BigDecimal adminFee;
    private BigDecimal trustFee;
    private BigDecimal totalFee;
    private BigDecimal ter;
    private BigDecimal frontLoadFee;
    private BigDecimal rearLoadFee;
}