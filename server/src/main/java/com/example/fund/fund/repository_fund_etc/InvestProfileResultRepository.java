package com.example.fund.fund.repository_fund_etc;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.fund.entity_fund_etc.InvestProfileResult;
import com.example.fund.user.entity.User;

public interface InvestProfileResultRepository extends JpaRepository<InvestProfileResult, Integer> {
	Optional<InvestProfileResult> findTopByUserOrderByAnalysisDateDesc(User user);
	Optional<InvestProfileResult> findByUser_UserId(Integer userId);
	
	// 사용자의 분석일 가져오기
	@Query("select r.analysisDate from InvestProfileResult r where r.user.userId = :userId")
	Optional<LocalDateTime> findAnalysisDateByUserId(@Param("userId") Integer userId);
	
}
