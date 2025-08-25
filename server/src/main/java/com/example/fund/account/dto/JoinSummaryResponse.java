package com.example.fund.account.dto;

import java.time.LocalDate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JoinSummaryResponse {
 private LocalDate tradeDate;      // D: 주문일(고객이 누른 날)
 private LocalDate navDate;        // T: 기준가 적용일
 private LocalDate processedAt;    // 체결일(좌수 반영일)
 private LocalDate settlementDate; // 정산일
}
