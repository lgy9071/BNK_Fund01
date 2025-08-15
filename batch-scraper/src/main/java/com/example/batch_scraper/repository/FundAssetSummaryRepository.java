package com.example.batch_scraper.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.batch_scraper.entity.Fund;
import com.example.batch_scraper.entity.FundAssetSummary;

@Repository
public interface FundAssetSummaryRepository extends JpaRepository<FundAssetSummary, Long> { 
	
	void deleteByFund(Fund fund);
}
