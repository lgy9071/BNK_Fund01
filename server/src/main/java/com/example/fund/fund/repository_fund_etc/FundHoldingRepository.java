package com.example.fund.fund.repository_fund_etc;

import com.example.fund.fund.entity_fund_etc.FundHolding;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FundHoldingRepository extends JpaRepository<FundHolding, Long> {
    List<FundHolding> findByUser_UserIdOrderByJoinedAtDesc(int userId);
}
