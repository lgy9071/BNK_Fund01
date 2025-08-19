package com.example.fund.fund.repository_fund;

import com.example.batch_scraper.entity.Fund;
import com.example.batch_scraper.entity.FundAssetSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FundAssetSummaryRepository extends JpaRepository<FundAssetSummary, Long> { 
	
	void deleteByFund(Fund fund);
}
