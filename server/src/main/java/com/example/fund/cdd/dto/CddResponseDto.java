package com.example.fund.cdd.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CddResponseDto {
    private String cddId;           // 예: "1"
    private String riskLevel;       // 예: "MEDIUM" (LOW/MEDIUM/HIGH)
    private String processedAt;     // 예: "2025-08-22T10:30:00" (ISO 8601 형식)
}