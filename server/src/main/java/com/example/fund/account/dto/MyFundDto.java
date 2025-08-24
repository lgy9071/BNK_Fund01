package com.example.fund.account.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MyFundDto {

    private Long fundId;           // Flutter의 id에 매핑 (fundAccountId 사용)
    private String fundName;       // Flutter의 name에 매핑
    private Double currentRate;    // Flutter의 rate에 매핑 (수익률 %)
    private Integer currentBalance; // Flutter의 balance에 매핑 (현재 평가액)
    private LocalDateTime joinedDate; // Flutter의 joinedDate에 매핑
    private String fundCode;       // Flutter의 fundCode에 매핑

    // 추가 정보 (선택사항)
    private BigDecimal units;           // 보유 좌수
    private BigDecimal totalInvested;   // 총 투자금액
    private BigDecimal fundValuation;   // 현재 평가액 (정확한 값)
}