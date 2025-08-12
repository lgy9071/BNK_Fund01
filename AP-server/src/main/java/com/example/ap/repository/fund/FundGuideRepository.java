package com.example.ap.repository.fund;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.FundGuide;

public interface FundGuideRepository extends JpaRepository<FundGuide, Integer> {
	
	List<FundGuide> findByCategory(String category);
}
