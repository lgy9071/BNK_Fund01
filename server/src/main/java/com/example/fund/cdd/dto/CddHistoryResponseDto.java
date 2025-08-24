package com.example.fund.cdd.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CddHistoryResponseDto {
    private String cddId;
    private String maskedRrn;           // 마스킹된 주민등록번호 (901225-1******)
    private String nationality;
    private String occupation;
    private String incomeSource;
    private String transactionPurpose;
    private String riskLevel;
    private Integer riskScore;
    private String processedAt;
}