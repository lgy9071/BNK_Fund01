package com.example.fund.fund.repository_fund_etc;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.fund.entity_fund_etc.InvestProfileResult;
import com.example.fund.user.entity.User;

public interface InvestProfileResultRepository extends JpaRepository<InvestProfileResult, Integer> {
	Optional<InvestProfileResult> findTopByUserOrderByAnalysisDateDesc(User user);

	Optional<InvestProfileResult> findByUser_UserId(Integer userId);

	// 최신 분석 1건 (userId로)
	Optional<InvestProfileResult> findTopByUser_UserIdOrderByAnalysisDateDesc(Integer userId);
}
