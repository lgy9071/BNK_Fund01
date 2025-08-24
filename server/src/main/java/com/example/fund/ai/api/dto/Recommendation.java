package com.example.fund.ai.api.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data 
@NoArgsConstructor 
@AllArgsConstructor 
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class Recommendation {
    // 기존: "보수형|중립형|공격형" 등 → 아래로 교체
    // "안정형|안정추구형|위험중립형|적극투자형|공격투자형|미설정"
    private String profile;
    private String pick;   // "A" | "B" | "tie"
    private String reason;
}
