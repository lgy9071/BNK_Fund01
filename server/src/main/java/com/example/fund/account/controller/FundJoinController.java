package com.example.fund.account.controller;

import java.math.BigDecimal;
import java.util.Map;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.account.dto.JoinCheckResponse;
import com.example.fund.account.service.FundInfoService;
import com.example.fund.account.service.FundJoinService;
import com.example.fund.common.CurrentUid;

import lombok.RequiredArgsConstructor;

@CrossOrigin(origins="*")
@RestController
@RequestMapping("/api/funds")
@RequiredArgsConstructor
public class FundJoinController {
	
	private final FundJoinService fundJoinService;
	private final FundInfoService fundInfoService;
	

	// 펀드 가입
	// 1) 입출금 계좌여부 판단
	@PostMapping("/checkUser")
	public JoinCheckResponse checkUser(@CurrentUid Integer uid) {
		boolean hasDepositAccount = fundJoinService.checkDepositAccount(uid);
		boolean hasValidInvestProfile = fundJoinService.checkInvestProfile(uid);
		
		String nextAction = "OK";
	    if (!hasDepositAccount) nextAction = "OPEN_DEPOSIT";
	    else if (!hasValidInvestProfile) nextAction = "DO_PROFILE";
		
		return new JoinCheckResponse(hasDepositAccount, hasValidInvestProfile, nextAction);
	}
	
	@GetMapping("/checkNavPrice")
	public Map<String, BigDecimal> checkNavPrice(@RequestParam String fundId) {
	    BigDecimal minAmount = fundInfoService.checkFundNavPrice(fundId);
	    return Map.of("minAmount", minAmount);
	}
	// 1-1) CDD 유효 확인
	// 2) 투자성향분석 여부 판단
	// 3) 약관동의
	// 4) 가입 방식 선택 -> 매일/매주/매월
	// 5) 가입 금액 입력 --> 기본 입출금 통장 사용
	// 7) 사후관리지점 선택
	// 펀드상품 ID와 사용자 정보를 받아와서
	public void fundJoin(@CurrentUid Integer uid) {
			
		}
	
	// 지점 관리
//	public Branch branch() {
//		
//	}
}
