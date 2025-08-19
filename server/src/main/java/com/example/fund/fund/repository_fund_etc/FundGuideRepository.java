package com.example.fund.fund.repository_fund_etc;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.fund.entity_fund_etc.FundGuide;

public interface FundGuideRepository extends JpaRepository<FundGuide, Integer> {
	
	List<FundGuide> findByCategory(String category);
}
