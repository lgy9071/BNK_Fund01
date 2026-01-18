package com.example.fund.admin.repository.projection;

/**
 * 투자자 프로필 통계용 JPA Projection
 * - 특정 타입(typeId)별 집계 수(cnt)를 조회하기 위한 인터페이스
 * - 네이티브 쿼리 또는 JPQL의 SELECT 절 alias와 매핑됨
 */
public interface InvestorProfileStat {
    Long getTypeId(); // 투자자 유형 ID
    Long getCnt();    // 해당 유형의 사용자 수
}