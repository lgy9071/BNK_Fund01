package com.example.fund.clickLog.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.clickLog.entity.FundClickLog;

public interface FundClickLogRepository extends JpaRepository<FundClickLog, Long> {
}
