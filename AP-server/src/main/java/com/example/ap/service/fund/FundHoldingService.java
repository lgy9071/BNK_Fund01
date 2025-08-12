package com.example.ap.service.fund;


import java.util.List;

import org.springframework.stereotype.Service;

import com.example.ap.repository.fund.FundHoldingRepository;
import com.example.common.entity.fund.FundHolding;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundHoldingService {

    private final FundHoldingRepository fundHoldingRepository;

    public List<FundHolding> getHoldingsByUserId(int userId) {
        return fundHoldingRepository.findByUser_UserIdOrderByJoinedAtDesc(userId);
    }
}
