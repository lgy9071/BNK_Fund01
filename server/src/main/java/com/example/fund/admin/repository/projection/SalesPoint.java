package com.example.fund.admin.repository.projection;

import java.math.BigDecimal;

/**
 * 매출 그래프(라인차트) 포인트 Projection
 * - label : 날짜/월
 * - value : 해당 기간의 매출 금액
 */
public interface SalesPoint {
    String getLabel();      // x축 라벨 (날짜 or 월)
    BigDecimal getValue();  // y축 값 (금액)
}