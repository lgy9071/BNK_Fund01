package com.example.common.dto.fund;

import java.math.BigDecimal;
import java.time.LocalDate;

import lombok.Data;

@Data
public class FundRegisterRequest {
    private Long fundId; 
    private BigDecimal fundPayout;
    private String fundTheme;
    private Boolean fundActive;
    private LocalDate fundRelease;
    private String docType;
    private String docTitle;
    private String fileFormat;
}
