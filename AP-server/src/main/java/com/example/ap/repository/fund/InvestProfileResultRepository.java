package com.example.ap.repository.fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.InvestProfileResult;
import com.example.common.entity.fund.User;

public interface InvestProfileResultRepository extends JpaRepository<InvestProfileResult, Integer> {
	Optional<InvestProfileResult> findTopByUserOrderByAnalysisDateDesc(User user);
	Optional<InvestProfileResult> findByUser_UserId(Integer userId);
}
