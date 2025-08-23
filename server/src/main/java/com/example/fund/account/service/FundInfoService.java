package com.example.fund.account.service;

import java.math.BigDecimal;

import org.springframework.stereotype.Service;

import com.example.fund.fund.repository_fund.FundRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundInfoService {
	
	private final FundRepository fundRepo;
	
	public BigDecimal checkFundNavPrice(String fundId) {
		
		return fundRepo.findMinSubscriptionAmountByFundId(fundId).get();

	}
	
//	public BigDecimal checkFundNavPrice(String fundId) {
//	    BigDecimal navPrice = fundStatusDailyRepo
//	            .findNavPriceByFundIdAndBaseDate(fundId, LocalDate.now())
//	            .orElseThrow(() -> new IllegalStateException("NAV not found for fundId=" + fundId));
//
//	    if (navPrice.signum() <= 0) {
//	        throw new IllegalStateException("Invalid NAV price: " + navPrice);
//	    }
//
//	    // ✅ NAV 가격을 1000원 단위에서 무조건 올림 (정수만 반환)
//	    BigDecimal unit = BigDecimal.valueOf(1000);
//	    return navPrice
//	            .divide(unit, 0, RoundingMode.CEILING) // 천원 단위로 나눈 뒤 무조건 올림
//	            .multiply(unit);                        // 다시 천원 단위 곱하기
//	}

}
