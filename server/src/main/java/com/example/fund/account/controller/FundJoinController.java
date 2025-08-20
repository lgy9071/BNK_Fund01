package com.example.fund.account.controller;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.account.entity.Branch;
import com.example.fund.common.CurrentUid;

@CrossOrigin(origins="*")
@RestController
@RequestMapping("/api")
public class FundJoinController {

	// 펀드 가입
	// 1) 입출금 계좌여부 판단
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
