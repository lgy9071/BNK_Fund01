package com.example.fund.clickLog.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.clickLog.entity.FundClickLog;
import com.example.fund.clickLog.repository.FundClickLogRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundClickLogService {
    private final FundClickLogRepository repo;

    @Transactional
    public void logClick(long fundId, long userId) {
        repo.save(FundClickLog.builder()
                .fundId(fundId)
                .userId(userId)
                .build());
    }
}
