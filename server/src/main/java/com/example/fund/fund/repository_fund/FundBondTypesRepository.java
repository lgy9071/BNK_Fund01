package com.example.fund.fund.repository_fund;

import com.example.batch_scraper.entity.Fund;
import com.example.batch_scraper.entity.FundBondTypes;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FundBondTypesRepository extends JpaRepository<FundBondTypes, Long> { 
	
	void deleteByFund(Fund fund);
}