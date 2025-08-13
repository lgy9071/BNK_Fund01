package com.example.batch_scraper.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

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
public class FundStatusDailyDto {
    // private Long fundStatusDailyId;
    private String fundId;
    private LocalDate baseDate;
    private BigDecimal navPrice;
    private BigDecimal navTotal;
    private BigDecimal originalPrincipal;
    private BigDecimal navChange1d;
    private BigDecimal navChangeRate1d;
    private BigDecimal navChange1w;
    private BigDecimal navChangeRate1w;
}