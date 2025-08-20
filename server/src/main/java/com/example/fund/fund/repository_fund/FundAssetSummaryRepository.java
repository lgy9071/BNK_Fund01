package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundAssetSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FundAssetSummaryRepository extends JpaRepository<FundAssetSummary, Long> {
	
	void deleteByFund(Fund fund);

	Optional<FundAssetSummary> findTopByFund_FundIdOrderByBaseDateDesc(String fundId);
}
