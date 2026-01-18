package com.example.fund.admin.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.admin.repository.projection.SalesPoint;
import com.example.fund.fund.entity_fund.Fund;

/**
 * 통계 전용 Repository
 * - 펀드/매출/클릭/대시보드 관련 통계 조회 담당
 */
public interface StatsRepository extends JpaRepository<Fund, String> {

    // ===========================
    // TOP5 인기 펀드 조회
    // ===========================

    /**
     * 인기 펀드 Projection (내부 인터페이스)
     */
    interface PopularFundView {
        String getFundId();
        String getFundName();
        String getManagementCompany();
        Long getClicks(); // 총 클릭 수
        Long getUsers();  // 유니크 사용자 수
    }

    /**
     * 클릭 로그 기반 TOP N 인기 펀드 조회
     * - 클릭 수 기준 내림차순
     * - Oracle ROWNUM 사용
     */
    @Query(value = """
        SELECT *
        FROM (
          SELECT
            f.fund_id                AS fundId,
            f.fund_name              AS fundName,
            f.management_company     AS managementCompany,
            COUNT(c.click_log_id)    AS clicks,
            COUNT(DISTINCT c.user_id) AS users
          FROM FUND f
          JOIN FUND_CLICK_LOG c
            ON c.fund_id = f.fund_id
          GROUP BY f.fund_id, f.fund_name, f.management_company
          ORDER BY COUNT(c.click_log_id) DESC
        )
        WHERE ROWNUM <= :limit
        """, nativeQuery = true)
    List<PopularFundView> findPopularFunds(@Param("limit") int limit);

    // ===========================
    // 펀드 개수 집계
    // ===========================

    /**
     * 전체 펀드 수 / 공개(PUBLISHED) 펀드 수 Projection
     */
    interface FundCountsRow {
        Long getTotal();     // 전체 펀드 수
        Long getPublished(); // 공개된 펀드 수
    }

    /**
     * 펀드 개수 집계
     * - dual 테이블 사용 (Oracle)
     */
    @Query(value = """
        SELECT
          (SELECT COUNT(*) FROM FUND) AS total,
          (SELECT COUNT(*) FROM FUND_PRODUCT WHERE LOWER(status) = 'published') AS published
        FROM dual
        """, nativeQuery = true)
    FundCountsRow fetchFundCounts();

    // ===========================
    // 일별 매출 추이
    // ===========================

    /**
     * 최근 N일간 매출 합계 조회
     * - PURCHASE / ADD_PUR 만 집계
     * - 거래일 기준
     */
    @Query(value = """
        WITH days AS (
          SELECT TRUNC(SYSDATE) - LEVEL + 1 AS d
          FROM dual CONNECT BY LEVEL <= :days
        )
        SELECT TO_CHAR(d.d, 'YYYY-MM-DD') AS label,
               NVL(SUM(t.amount), 0)      AS value
        FROM days d
        LEFT JOIN FUND_TRANSACTION t
          ON TRUNC(COALESCE(t.trade_date, t.processed_at, CAST(t.requested_at AS DATE))) = d.d
         AND t.tx_type IN ('PURCHASE','ADD_PUR')
        GROUP BY d.d
        ORDER BY d.d
        """, nativeQuery = true)
    List<SalesPoint> salesDaily(@Param("days") int days);

    // ===========================
    // 월별 매출 추이
    // ===========================

    /**
     * 최근 N개월 매출 합계 조회
     */
    @Query(value = """
        WITH months AS (
          SELECT ADD_MONTHS(TRUNC(SYSDATE,'MM'), -(LEVEL-1)) AS m
          FROM dual CONNECT BY LEVEL <= :months
        )
        SELECT TO_CHAR(m.m, 'YYYY-MM') AS label,
               NVL(SUM(t.amount), 0)   AS value
        FROM months m
        LEFT JOIN FUND_TRANSACTION t
          ON TRUNC(COALESCE(t.trade_date, t.processed_at, CAST(t.requested_at AS DATE)),'MM') = m.m
         AND t.tx_type IN ('PURCHASE','ADD_PUR')
        GROUP BY m.m
        ORDER BY m.m
        """, nativeQuery = true)
    List<SalesPoint> salesMonthly(@Param("months") int months);
}