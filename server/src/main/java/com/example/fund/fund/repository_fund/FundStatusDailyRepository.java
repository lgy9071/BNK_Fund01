package com.example.fund.fund.repository_fund;

import java.time.LocalDate;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundStatusDaily;

@Repository
public interface FundStatusDailyRepository extends JpaRepository<FundStatusDaily, Long> {
	
	boolean existsByFundAndBaseDate(Fund fund, LocalDate baseDate);
	
	Optional<FundStatusDaily> findByFund_FundIdAndBaseDate(String fundId, LocalDate baseDate);
}
