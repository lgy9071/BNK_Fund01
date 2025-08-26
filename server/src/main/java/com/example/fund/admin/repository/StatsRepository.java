package com.example.fund.admin.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.admin.repository.projection.SalesPoint;
import com.example.fund.fund.entity_fund.Fund;

public interface StatsRepository extends JpaRepository<Fund, String> {

    // ---------- TOP5 인기 펀드 ----------
    interface PopularFundView {
        String getFundId();
        String getFundName();
        String getManagementCompany();
        Long getClicks();
        Long getUsers();
    }

    @Query(value = """
        SELECT *
        FROM (
          SELECT
            f.fund_id                AS fundId,
            f.fund_name              AS fundName,
            f.management_company     AS managementCompany,
            COUNT(c.click_log_id)    AS clicks,                 -- 총 클릭수
            COUNT(DISTINCT c.user_id) AS users                  -- 유니크 사용자
          FROM FUND f
          JOIN FUND_CLICK_LOG c
            ON c.fund_id = f.fund_id
          GROUP BY f.fund_id, f.fund_name, f.management_company
          ORDER BY COUNT(c.click_log_id) DESC
        )
        WHERE ROWNUM <= :limit
        """, nativeQuery = true)
    List<PopularFundView> findPopularFunds(@Param("limit") int limit);

    // ---------- 펀드 수 집계 ----------
    interface FundCountsRow {
        Long getTotal();
        Long getPublished();
    }

    @Query(value = """
        SELECT
          (SELECT COUNT(*) FROM FUND) AS total,
          (SELECT COUNT(*) FROM FUND_PRODUCT WHERE LOWER(status) = 'published') AS published
        FROM dual
        """, nativeQuery = true)
    FundCountsRow fetchFundCounts();

    // ---------- 판매 금액 추이(일별) ----------
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
         AND t.tx_type IN ('PURCHASE','ADD_PUR')      -- 매수/추가매수만 합산
        GROUP BY d.d
        ORDER BY d.d
        """, nativeQuery = true)
    List<SalesPoint> salesDaily(@Param("days") int days);

    // ---------- 판매 금액 추이(월별) ----------
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
         AND t.tx_type IN ('PURCHASE','ADD_PUR')      -- 매수/추가매수만 합산
        GROUP BY m.m
        ORDER BY m.m
        """, nativeQuery = true)
    List<SalesPoint> salesMonthly(@Param("months") int months);
}
