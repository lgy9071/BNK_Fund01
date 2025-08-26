package com.example.fund.account.controller;

import java.math.BigDecimal;
import java.net.URI;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.account.dto.AgreementConfirmRequest;
import com.example.fund.account.dto.DocumentInfoDto;
import com.example.fund.account.dto.FundJoinRequest;
import com.example.fund.account.dto.JoinCheckResponse;
import com.example.fund.account.entity.TermsAgreement;
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
	// 펀드가입 조건 조회 -- 입출금 계좌 여부, 투자성향분석 여부
	@PostMapping("/checkUser")
	public JoinCheckResponse checkUser(@CurrentUid Integer uid) {
		boolean hasDepositAccount = fundJoinService.checkDepositAccount(uid);
		boolean hasValidInvestProfile = fundJoinService.checkInvestProfile(uid);
		
		String nextAction = "OK";
	    if (!hasDepositAccount) nextAction = "OPEN_DEPOSIT";
	    else if (!hasValidInvestProfile) nextAction = "DO_PROFILE";
		
		return new JoinCheckResponse(hasDepositAccount, hasValidInvestProfile, nextAction);
	}
	
	// 기준가 조회
	@GetMapping("/checkNavPrice")
	public Map<String, BigDecimal> checkNavPrice(@RequestParam String fundId) {
	    BigDecimal minAmount = fundInfoService.checkFundNavPrice(fundId);
	    return Map.of("minAmount", minAmount);
	}
	
	// 계좌 번호 조회
		@GetMapping("/depositAccountNum")
		public String getAccountNummber(@CurrentUid Integer uid) {
			return fundJoinService.getAccountNumber(uid);
		}
		
		@PostMapping("/join")
		public ResponseEntity<?> join(@CurrentUid Integer uid, @RequestBody FundJoinRequest req) {
		    Long txId = fundJoinService.fundJoinAndReturnTxId(
		        uid,
		        req.getFundId(),
		        req.getAmount(),
		        req.getRawPin(),
		        req.getBranchName(),
		        req.getRuleType(),
		        req.getRuleValue()
		    );

		    // Location: /api/funds/join/summary/{txId}
		    URI location = URI.create(String.format("/api/funds/join/summary/%d", txId));
		    return ResponseEntity
		            .created(location)
		            .body(Map.of("transactionId", txId));
		}

		
	
	// 1-1) CDD 유효 확인
	// 2) 투자성향분석 여부 판단
	// 3) 약관동의
	// 4) 가입 방식 선택 -> 매일/매주/매월
	// 5) 가입 금액 입력 --> 기본 입출금 통장 사용
	// 7) 사후관리지점 선택
	// 펀드상품 ID와 사용자 정보를 받아와서
		@GetMapping("/join/summary/{transactionId}")
		public ResponseEntity<?> joinSummaryByTxId(@CurrentUid Integer uid,
		        @org.springframework.web.bind.annotation.PathVariable Long transactionId) {
		    return ResponseEntity.ok(fundJoinService.getJoinDates(uid, transactionId));
		}
		
		 @GetMapping("/{fundId}/documents")
		    public List<DocumentInfoDto> getDocs(@PathVariable String fundId) {
		        return fundInfoService.getRequiredDocs(fundId);
		    }
		 
		 @PostMapping("/confirm")
		    public ResponseEntity<TermsAgreement> confirm(@CurrentUid Integer uid,
		    											  @RequestBody AgreementConfirmRequest req) {
		        // 1) 프런트에서 두 체크를 동시에 보냈는지 1차 검증
		        if (!req.termsAgreed() || !req.docConfirmed()) {
		            return ResponseEntity.badRequest().build();
		        }

		        // 2) 서비스 호출 (당일 유효한 동의가 있으면 그대로 반환, 없으면 새로 생성)
		        TermsAgreement saved = fundJoinService.createActiveAfterCompletion(uid, req.productId());

		        return ResponseEntity.ok(saved);
		    }
		 @GetMapping("/confirm")
		 public ResponseEntity<?> hasTodayAgreement(@CurrentUid Integer uid,
		                                            @RequestParam Long productId) {
		     boolean exists = fundJoinService.hasActiveAgreementToday(uid, productId);
		     if (exists) return ResponseEntity.ok().build();
		     return ResponseEntity.noContent().build(); // 204
		 }

	
	// 지점 관리
//	public Branch branch() {
//		
//	}
}
