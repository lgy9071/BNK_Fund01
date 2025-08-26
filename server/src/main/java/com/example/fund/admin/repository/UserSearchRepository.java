package com.example.fund.admin.repository;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.user.entity.User;

public interface UserSearchRepository extends JpaRepository<User, Long> {

    @Query(value = """
        SELECT u.USER_ID AS userId,
            u.EMAIL   AS email,
            u.NAME    AS name,
            u.PHONE   AS phone
        FROM TBL_USER u
        WHERE
            ( :qLower IS NOT NULL AND (
                    LOWER(u.EMAIL) LIKE '%' || :qLower || '%'
                OR LOWER(u.NAME)  LIKE '%' || :qLower || '%'
            ))
            OR ( :digits IS NOT NULL AND (
                    REPLACE(u.PHONE,'-','') LIKE '%' || :digits || '%'
                OR ( :hyphen IS NOT NULL AND u.PHONE = :hyphen )
            ))
        ORDER BY u.USER_ID DESC
        FETCH FIRST 100 ROWS ONLY
        """, nativeQuery = true)
    List<UserListRow> searchList(@Param("qLower") String qLower,
                                @Param("digits") String digits,
                                @Param("hyphen") String hyphen);

    interface UserListRow {              // ← 프로젝션 이름도 searchList에 맞춤
        Long getUserId();
        String getEmail();
        String getName();
        String getPhone();
    }

    // ── 펀드 가입 집계 (그대로 OK)
    @Query(value = """
        SELECT
            f.FUND_ID          AS fundId,
            f.FUND_NAME        AS fundName,
            SUM(CASE
                  WHEN t.TYPE IN ('매수','추가매수') THEN NVL(t.AMOUNT,0)
                  WHEN t.TYPE = '환매'               THEN -NVL(t.AMOUNT,0)
                  ELSE 0
                END)            AS netAmount,
            MIN(CASE
                  WHEN t.TYPE IN ('매수','추가매수') THEN t.TRADE_DATE
                END)            AS firstSubscribedAt
        FROM FUND_TRANSACTION t
        JOIN TBL_FUND f ON f.FUND_ID = t.FUND_ID
        WHERE t.USER_ID = :userId
        GROUP BY f.FUND_ID, f.FUND_NAME
        HAVING SUM(CASE
                  WHEN t.TYPE IN ('매수','추가매수') THEN NVL(t.AMOUNT,0)
                  WHEN t.TYPE = '환매'               THEN -NVL(t.AMOUNT,0)
                  ELSE 0 END) > 0
        ORDER BY MIN(CASE WHEN t.TYPE IN ('매수','추가매수') THEN t.TRADE_DATE END)
        """, nativeQuery = true)
    List<UserFundAggRow> findUserFundAgg(@Param("userId") Long userId);

    interface UserFundAggRow {
        Long getFundId();
        String getFundName();
        BigDecimal getNetAmount();
        Timestamp getFirstSubscribedAt();
    }

    @Query(value = """
        SELECT u.USER_ID   AS userId,
               u.NAME      AS name,
               u.EMAIL     AS email,
               u.PHONE     AS phone,
               u.USERNAME  AS username
        FROM TBL_USER u
        WHERE u.USER_ID = :id
        """, nativeQuery = true)
    UserDetailRow findDetail(@Param("id") Long id);

    interface UserDetailRow {
        Long getUserId();
        String getName();
        String getEmail();
        String getPhone();
        String getUsername();
    }
}


