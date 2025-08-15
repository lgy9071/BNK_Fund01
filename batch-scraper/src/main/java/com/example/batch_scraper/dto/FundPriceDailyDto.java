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
public class FundPriceDailyDto {
    private String fundId;
    private LocalDate baseDate;
    private BigDecimal navPrice;
    private BigDecimal navChange;
    private BigDecimal taxPrice;
    private BigDecimal originalPrincipal;
    private BigDecimal kospi;
    private BigDecimal kospi200;
    private BigDecimal kosdaq;
    private BigDecimal treasury3y;
    private BigDecimal corpBond3y;
}
