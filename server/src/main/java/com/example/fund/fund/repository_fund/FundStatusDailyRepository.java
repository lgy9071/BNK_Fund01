package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundStatusDaily;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;


@Repository
public interface FundStatusDailyRepository extends JpaRepository<FundStatusDaily, Long> {

    boolean existsByFundAndBaseDate(
			Fund fund,
			LocalDate baseDate
	);

    @Query("select d.navPrice from FundStatusDaily d " +
            "where d.fund.fundId = :fundId and d.baseDate = :baseDate")
    Optional<BigDecimal> findNavPriceByFundIdAndBaseDate(
            @Param("fundId") String fundId,
            @Param("baseDate") LocalDate baseDate
    );

    Optional<FundStatusDaily> findTopByFund_FundIdOrderByBaseDateDesc(
            String fundId
    );

    // 특정 펀드의 최신 기준가 조회
    @Query("""
            SELECT fsd 
            FROM FundStatusDaily fsd 
            WHERE fsd.fund.fundId = :fundId 
              AND fsd.baseDate = (
                  SELECT MAX(fsd2.baseDate) 
                  FROM FundStatusDaily fsd2 
                  WHERE fsd2.fund.fundId = :fundId
              )
            """)
    Optional<FundStatusDaily> findLatestByFundId(
            @Param("fundId") String fundId
    );

    // 여러 펀드의 최신 기준가 일괄 조회
    @Query("""
            SELECT fsd 
            FROM FundStatusDaily fsd 
            WHERE fsd.fund.fundId IN :fundIds 
              AND fsd.baseDate = (
                  SELECT MAX(fsd2.baseDate) 
                  FROM FundStatusDaily fsd2 
                  WHERE fsd2.fund.fundId = fsd.fund.fundId
              )
            """)
    List<FundStatusDaily> findLatestByFundIds(
            @Param("fundIds") List<String> fundIds
    );
}
