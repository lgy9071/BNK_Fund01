package com.example.fund.admin.repository.projection;

/* JPA projection for status/count */
/**
 * 상태별 개수 집계 Projection
 * - 예: 승인상태, 처리상태별 건수 통계
 */
public interface StatusCount {
    String getStatus(); // 상태값
    Long getCnt();      // 해당 상태의 개수
}