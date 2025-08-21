package com.example.fund.fund.repository_fund;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundStatusDaily;

@Repository
public interface FundStatusDailyRepository extends JpaRepository<FundStatusDaily, Long> {
	
	boolean existsByFundAndBaseDate(Fund fund, LocalDate baseDate);
	
	@Query("select d.navPrice from FundStatusDaily d " +
	           "where d.fund.fundId = :fundId and d.baseDate = :baseDate")
	    Optional<BigDecimal> findNavPriceByFundIdAndBaseDate(@Param("fundId") String fundId,
	                                                         @Param("baseDate") LocalDate baseDate);
}
