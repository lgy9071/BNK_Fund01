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
public class FundBondTypesDto {
    // private Long fundBondTypesId;
    private String fundId;
    private BigDecimal govBondRatio;
    private BigDecimal moaBondRatio;
    private BigDecimal finBondRatio;
    private BigDecimal corpBondRatio;
    private BigDecimal otherRatio;
}