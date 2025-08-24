package com.example.fund.fund.repository_fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.fund.entity_fund.ReviewAiSummary;

public interface ReviewAiSummaryRepository extends JpaRepository<ReviewAiSummary, Long>{
    Optional<ReviewAiSummary> findByFundId(String fundId);
    boolean existsByFundId(String fundId);
}
