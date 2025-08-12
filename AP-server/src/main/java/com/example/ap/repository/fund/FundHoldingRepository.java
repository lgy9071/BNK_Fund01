package com.example.ap.repository.fund;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.FundHolding;

public interface FundHoldingRepository extends JpaRepository<FundHolding, Long> {
    List<FundHolding> findByUser_UserIdOrderByJoinedAtDesc(int userId);
}
