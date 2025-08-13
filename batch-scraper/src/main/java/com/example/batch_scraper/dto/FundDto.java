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
public class FundDto {
    
    private String fundId;
    private String fundName;
    private String fundType;
    private String fundDivision;
    private String investmentRegion;
    private String salesRegionType;
    private String groupCode;
    private String shortCode;
    private LocalDate issueDate;
    private BigDecimal initialNavPrice;
    private Integer trustTerm;
    private Integer accountingPeriod;
    private String fundClass;
    private String publicType;
    private String addUnitType;
    private String fundStatus;
    private String riskGrade;
    private String performanceDisclosure;
    private String managementCompany;
    private BigDecimal minSubscriptionAmount;
}