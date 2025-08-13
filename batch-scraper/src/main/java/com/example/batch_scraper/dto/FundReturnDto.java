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
public class FundReturnDto {
    // private Long fundReturnId;
    private String fundId;
    private LocalDate baseDate;
    private BigDecimal return1m;
    private BigDecimal return3m;
    private BigDecimal return6m;
    private BigDecimal return12m;
}