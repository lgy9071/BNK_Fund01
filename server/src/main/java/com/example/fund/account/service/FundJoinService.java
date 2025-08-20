package com.example.fund.account.service;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.example.fund.account.entity.DepositAccount;
import com.example.fund.account.entity.DepositTransaction;
import com.example.fund.account.entity.FundAccount;
import com.example.fund.account.repository.DepositAccountRepository;
import com.example.fund.account.repository.DepositTransactionRepository;
import com.example.fund.account.repository.FundAccountRepository;
import com.example.fund.account.repository.FundTransactionRepository;
import com.example.fund.account.repository.TransitAccountRepository;
import com.example.fund.account.repository.TransitTransactionRepository;
import com.example.fund.fund.entity_fund.FundProduct;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;
import com.example.fund.user.entity.User;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;


@Service
@RequiredArgsConstructor
public class FundJoinService {
	
	private final DepositAccountRepository depositAccountRepo;
	private final InvestProfileResultRepository investProfileResultRepo;
	private final FundAccountRepository fundAccountRepo;
	private final DepositTransactionRepository depositTransactionRepo;
	private final FundTransactionRepository fundTransactionRepo;
	private final TransitAccountRepository transitAccountRepo;
	private final TransitTransactionRepository transitTransactionRepo;

	private final BCryptPasswordEncoder passwordEncoder;
	
	// 1) 입출금계좌 여부 확인 -- T/F
	public boolean checkDepositAccount(Integer userId) {
		boolean check = depositAccountRepo.existsByUser_UserId(userId);
		return check;
	}
	
	// 2) 투자성향분석 여부 확인 
	// - 분석 X or 1년 만료
	public boolean checkInvestProfile(Integer userId) {
		Optional<LocalDateTime> result = investProfileResultRepo.findAnalysisDateByUserId(userId);
		boolean check = true;
		if(result.isEmpty()) {
			// 분석이력X
			check = false;
		}else {
			LocalDateTime analysisDate = result.get();
			if(!analysisDate.plusYears(1).isAfter(LocalDateTime.now())) { // 1년 만료 시
				check = false;
			}
		}
		return check;
	}
	
	// 3) 펀드 계좌 생성 (잔액 : 0원)
	
	// Service 내부에 보관 (스레드 안전한 SecureRandom 재사용 권장)
	private static final SecureRandom RND = new SecureRandom();
	
	@Transactional
	   public FundAccount createFundAccount(User user, FundProduct fund, String rawPin) {
	      if(user == null || user.getUserId() == null) throw new IllegalArgumentException("userId가 필요합니다.");
	      if(fund == null || fund.getProductId() == null) throw new IllegalArgumentException("productId가 필요합니다.");
	      if(rawPin == null || rawPin.isBlank()) throw new IllegalArgumentException("PIN이 필요합니다.");
	      
	      // 계좌번호 생성
	      String accountNumber = generateUniqueAccountNumber();
	      
	      // 사용자가 입력한 비밀번호 → 암호화
	      String pinHash = passwordEncoder.encode(rawPin);
	      
	      FundAccount fundAccount = FundAccount.builder()
	                                 .user(user)
	                                 .fundProduct(fund)
	                                 .fundAccountNumber(accountNumber)
	                                 .fundPinHash(pinHash)
	                                 .units(BigDecimal.ZERO.setScale(4))
	                                    .lockedUnits(BigDecimal.ZERO.setScale(4))
	                                    .availableAmount(BigDecimal.ZERO.setScale(0))
	                                    .totalInvested(BigDecimal.ZERO.setScale(0))
	                                    .avgUnitPrice(BigDecimal.ZERO.setScale(2))
	                                    .fundValuation(BigDecimal.ZERO.setScale(2))
	                                    .status(FundAccount.FundAccountStatus.NORMAL)
	                                    .build();
	      
	      return fundAccountRepo.save(fundAccount);
	   }
	   
	   private String generateUniqueAccountNumber() {
	      while(true) {
	         String candidate = newAccountNumber();
	         if(!fundAccountRepo.existsByFundAccountNumber(candidate)) {
	            return candidate;
	         }
	      }
	   }


	/* 포맷: 125XXXXXXXXXXYY (하이픈 없는 버전) */
	private String newAccountNumber() {
	    int part1 = RND.nextInt(10000);
	    int part2 = RND.nextInt(10000);
	    String raw = String.format("125%04d%04d", part1, part2); // 125 + 8자리
	    int checksum = mod97(raw);
	    return String.format("125%04d%04d%02d", part1, part2, checksum); // 최종 13자리
	}

	// 체크섬 규칙: "125 + 8자리 난수"를 mod 97로 계산한 결과 (00~96) → 2자리 표시
	private int mod97(String digits) {
	    int rem = 0;
	    for (int i = 0; i < digits.length(); i++) {
	        rem = (rem * 10 + (digits.charAt(i) - '0')) % 97;
	    }
	    return rem;
	}
	// 히히
	// 체크섬 검증
	private boolean verifyAccountNumber(String formatted) {
	    // 유효성 검사 (하이픈 없는 13자리 숫자)
	    if (formatted == null || !formatted.matches("^125\\d{10}$")) {
	        return false;
	    }
	    try {
	        String raw = formatted.substring(0, 11);  // 앞의 11자리 (체크섬 제외)
	        int checksum = Integer.parseInt(formatted.substring(11)); // 마지막 2자리 체크섬
	        return mod97(raw) == checksum;
	    } catch (NumberFormatException | IndexOutOfBoundsException e) {
	        return false;
	    }
	}

	
	// 3) 입출금 -> 대기 : 대기계좌에 임시입금
	// 입출금 거래 내역 & 대기계좌내역 생성
	 public void accountTransaction(User user, BigDecimal orderAmount) {
		 DepositAccount depositAccount =depositAccountRepo.findByUser_UserId(user.getUserId()).get();
		 BigDecimal currentBalance = depositAccount.getBalance(); // 입출금 통장 현재 잔액
//		 DepositTransaction depositTransaction = depositTransactionRepo.findByUser_UserId(user.getUserId()).get();
		 if(currentBalance.compareTo(orderAmount) >= 0) {
			 
			 // 1) 입출금 계좌에서 주문금액만큼 출금
			 depositAccount.setBalance(currentBalance.subtract(orderAmount));
			 
			 // 2) 입출금 거래 내역 생성
//			depositTransaction.builder()
//							  .account(depositAccount)
//							  .txType(출금)
//							  .amount(orderAmount)
			 
			 
			 // 3) 대기 계좌에 주문금액만큼 입금
			 // 4) 대기 계좌 내역 생성
			 
			 
		 }
		 
		
		 
	 }
	
	// 4) 펀드거래내역 생성
	
	// 5) 매수일에 대기 -> 펀드 로 잔액 이동
	
	
	
	// 임시저장
	
	// 사후 관리지점

}
