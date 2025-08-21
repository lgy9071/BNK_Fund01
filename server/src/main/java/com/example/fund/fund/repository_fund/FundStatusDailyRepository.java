package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundStatusDaily;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface FundStatusDailyRepository extends JpaRepository<FundStatusDaily, Long> {
	
	boolean existsByFundAndBaseDate(Fund fund, LocalDate baseDate);

	Optional<FundStatusDaily> findTopByFund_FundIdOrderByBaseDateDesc(String fundId);
}
